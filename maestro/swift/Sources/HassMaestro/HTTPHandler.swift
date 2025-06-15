import NIO
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private var requestHead: HTTPRequestHead?

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch self.unwrapInboundIn(data) {
        case .head(let head):
            self.requestHead = head
        case .body:
            break
        case .end:
            handleRequest(context: context)
        }
    }

    private func handleRequest(context: ChannelHandlerContext) {
        guard let head = requestHead else { return }
        let keepAlive = head.isKeepAlive
        if head.method == .GET && head.uri == "/run" {
            var buffer = context.channel.allocator.buffer(string: "Run started")
            var headers = HTTPHeaders()
            headers.add(name: "Content-Length", value: String(buffer.readableBytes))
            let responseHead = HTTPResponseHead(version: head.version, status: .ok, headers: headers)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        } else {
            var buffer = context.channel.allocator.buffer(string: "Not Found")
            var headers = HTTPHeaders()
            headers.add(name: "Content-Length", value: String(buffer.readableBytes))
            let responseHead = HTTPResponseHead(version: head.version, status: .notFound, headers: headers)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }
        context.writeAndFlush(self.wrapOutboundOut(.end(nil))).whenComplete { _ in
            if !keepAlive {
                context.close(promise: nil)
            }
        }
    }
}
