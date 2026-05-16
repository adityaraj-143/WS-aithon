const express = require("express");
const fs = require("fs");
const path = require("path");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const PORT = 3001;

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" }
});

// In-memory store for active users
// This is temporary memory (lost on server restart)
const activeUsers = new Map()

io.on("connection", (socket) => {

  // Log every new socket connection
  console.log("🔌 New socket connected:", socket.id)

  /**
   * EVENT: connect_user
   * Triggered when iOS app launches
   * Sends user identity to backend
   */
  socket.on("connect_user", (data) => {

    const { userId, displayName } = data

    // Store user in memory map
    activeUsers.set(userId, {
      socketId: socket.id,
      displayName
    })

    // DEBUG LOG 1: single user added
    console.log("👤 User added:")
    console.log(data)

    // DEBUG LOG 2: full active user list
    console.log("📌 Active Users Now:")
    console.log(Array.from(activeUsers.entries()))
  })

  /**
   * HANDLE DISCONNECT
   */
  socket.on("disconnect", () => {

    console.log("❌ Socket disconnected:", socket.id)

    // Remove user from memory when socket disconnects
    for (let [userId, userData] of activeUsers.entries()) {
      if (userData.socketId === socket.id) {
        activeUsers.delete(userId)
        break
      }
    }

    // DEBUG LOG after removal
    console.log("📌 Active Users After Disconnect:")
    console.log(Array.from(activeUsers.entries()))
  })

})

app.use(express.json());

// Serve image files from the local "images" directory
// Handles URLs like /images//img17m.jpg (double-slash from paths starting with "/")
app.use("/images", express.static(path.join(__dirname, "images")));

function readJson(fileName) {
  const filePath = path.join(__dirname, "responses", fileName);
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function delayedJson(res, fileName, status = 200, delay = 500) {
  setTimeout(() => {
    res.status(status).json(readJson(fileName));
  }, delay);
}

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.post("/login", (req, res) => {
  const { email, password } = req.body || {};
  if (email === "demo@hackathon.com" && password === "123456") {
    return delayedJson(res, "login_success.json", 200, 400);
  }
  return delayedJson(res, "error_401.json", 401, 400);
});

app.get("/profile", (req, res) => {
  return delayedJson(res, "profile.json", 200, 600);
});

app.get("/feed", (req, res) => {
  return delayedJson(res, "feed.json", 200, 700);
});

app.get("/skus", (req, res) => {
  return delayedJson(res, "skus.json", 200, 700);
});


server.listen(PORT, "0.0.0.0", () => {
  console.log(`Mock API running on http://0.0.0.0:${PORT}`);
});