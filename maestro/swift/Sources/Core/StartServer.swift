import Foundation
import NIO
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let maestro: Maestro
    private var uri: String = "/"

    init(maestro: Maestro) {
        self.maestro = maestro
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        switch part {
        case .head(let head):
            uri = head.uri
        case .end:
            respond(context: context)
        case .body:
            break
        }
    }

    private func respond(context: ChannelHandlerContext) {
        var head = HTTPResponseHead(version: .http1_1, status: .ok)
        var body = "OK"
        if uri == "/run" {
            maestro.run()
        } else {
            head.status = .notFound
            body = "Not Found"
        }
        head.headers.add(name: "Content-Length", value: "\(body.utf8.count)")
        context.write(self.wrapOutboundOut(.head(head)), promise: nil)
        var buffer = context.channel.allocator.buffer(string: body)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}

/// HTTP server built with SwiftNIO.
func startServer(on port: Int32, maestro: Maestro) throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    let bootstrap = ServerBootstrap(group: group)
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelInitializer { channel in
            channel.pipeline.configureHTTPServerPipeline().flatMap {
                channel.pipeline.addHandler(HTTPHandler(maestro: maestro))
            }
        }
        .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)

    let channel = try bootstrap.bind(host: "0.0.0.0", port: Int(port)).wait()
    print("Server listening on port \(port)")
    try channel.closeFuture.wait()
    try group.syncShutdownGracefully()
}
