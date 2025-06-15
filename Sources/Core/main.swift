import Foundation

let options = parseArguments(CommandLine.arguments)
let maestro = Maestro(options: options)
try startServer(on: options.port, maestro: maestro)
