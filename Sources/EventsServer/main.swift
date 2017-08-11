import Kitura
import LoggerAPI
import HeliumLogger
import Foundation
import EventsService
import MySQL

// Disable stdout buffering (so log will appear)
setbuf(stdout, nil)

// Init logger
HeliumLogger.use(.info)

// Create connection string (use env variables, if exists)
let env = ProcessInfo.processInfo.environment
var connectionString = MySQLConnectionString(host: env["MYSQL_HOST"] ?? "localhost")
if let portString = env["MYSQL_PORT"], let port = Int(portString) {
  connectionString.port = port
}
connectionString.user = env["MYSQL_USER"] ?? "root"
connectionString.password = env["MYSQL_PASSWORD"] ?? "password"
connectionString.database = env["MYSQL_DATABASE"] ?? "game-night"

// Create connection pool
var pool = MySQLConnectionPool(connectionString: connectionString, poolSize: 10, defaultCharset: "utf8mb4")

// Create handlers
let handlers = Handlers(connectionPool: pool)

// Create router
let router = Router()

// Setup paths
router.all("/*", middleware: BodyParser())
router.all("/*", middleware: AllRemoteOriginMiddleware())
router.all("/*", middleware: LoggerMiddleware())
router.options("/*", handler: handlers.getOptions)

// GET
router.get("/*", middleware: CheckRequestMiddleware(method: .get))
router.get("/events", handler: handlers.getEvents)
router.get("/events/:id", handler: handlers.getEvents)

// POST
router.post("/*", middleware: CheckRequestMiddleware(method: .post))

// PUT
router.put("/*", middleware: CheckRequestMiddleware(method: .put))

// DELETE
router.delete("/*", middleware: CheckRequestMiddleware(method: .delete))

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
