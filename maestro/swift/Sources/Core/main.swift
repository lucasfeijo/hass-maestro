import Foundation

let options = parseArguments(CommandLine.arguments)
let maestro = makeMaestro(from: options)
try startServer(on: options.port, maestro: maestro)
