import Foundation

let options = parseArguments(CommandLine.arguments)
let maestro = makeMaestro(from: options)
#if !TESTING
try startServer(on: options.port, maestro: maestro, options: options)
#endif

