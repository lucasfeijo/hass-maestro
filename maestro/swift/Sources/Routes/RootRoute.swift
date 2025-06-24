import Foundation

func handleRootRoute(method: Substring, request: String, maestro: inout Maestro, options: inout MaestroOptions, defaultStepNames: [String]) -> (statusLine: String, headers: [String], body: String) {
    if method == "POST" {
        if let bodyPart = request.components(separatedBy: "\r\n\r\n").last {
            var order: [String] = []
            var skips: Set<String> = []
            for pair in bodyPart.split(separator: "&") {
                let kv = pair.split(separator: "=", maxSplits: 1)
                guard let name = kv.first else { continue }
                let value = kv.count > 1 ? String(kv[1]).removingPercentEncoding ?? "" : ""
                let key = String(name)
                if key == "step" {
                    order.append(value)
                } else if key.hasPrefix("skip_") {
                    skips.insert(String(key.dropFirst(5)))
                }
            }
            if !order.isEmpty {
                let programString = order.map { skips.contains($0) ? "!\($0)" : $0 }.joined(separator: ",")
                options.programName = programString
                maestro = makeMaestro(from: options)
            }
        }
        return ("HTTP/1.1 302 Found", ["Location: /"], "")
    } else {
        let steps = currentProgramSteps(options: options, defaultStepNames: defaultStepNames)
        let listItems = steps.map { name, skip in
            """
            <li class="list-group-item d-flex justify-content-between align-items-center">
            <input type="hidden" name="step" value="\(name)">
            <span>\(name)</span>
            <div>
            <label class="form-check-label me-2"><input class="form-check-input me-1" type="checkbox" name="skip_\(name)" \(skip ? "checked" : "")>Skip</label>
            <button type="button" class="btn btn-sm btn-secondary move-up">&#8679;</button>
            <button type="button" class="btn btn-sm btn-secondary move-down ms-1">&#8681;</button>
            </div></li>
            """
        }.joined()

        let body = """
        <html>
        <head>
        <title>Hass Maestro</title>
        <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css\">
        </head>
        <body class=\"container py-3\">
        <h1>Maestro Options</h1>
        <form method=\"POST\" action=\"/\">
        <ul class=\"list-group mb-3\" id=\"step-list\">\(listItems)</ul>
        <button type=\"submit\" class=\"btn btn-primary\">Save</button>
        <a href=\"/run\" class=\"btn btn-success ms-2\">Run now</a>
        </form>
        <script>
        document.querySelectorAll('.move-up').forEach(function(btn){
          btn.addEventListener('click', function(){
            var li = this.closest('li');
            if(li.previousElementSibling){ li.parentNode.insertBefore(li, li.previousElementSibling); }
          });
        });
        document.querySelectorAll('.move-down').forEach(function(btn){
          btn.addEventListener('click', function(){
            var li = this.closest('li');
            if(li.nextElementSibling){ li.parentNode.insertBefore(li.nextElementSibling, li); }
          });
        });
        </script>
        </body>
        </html>
        """
        return ("HTTP/1.1 200 OK", ["Content-Type: text/html; charset=utf-8"], body)
    }
}

private func currentProgramSteps(options: MaestroOptions, defaultStepNames: [String]) -> [(String, Bool)] {
    let raw = options.programName?.split(separator: ",").map(String.init) ?? defaultStepNames
    return raw.map { part in
        if part.hasPrefix("!") {
            return (String(part.dropFirst()), true)
        } else {
            return (part, false)
        }
    }
}
