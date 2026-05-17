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

/**
 * Requirement 2: Backend should maintain an in-memory active users map:
 * Map<userId, { socketId, displayName }>
 */
let activeUsers = new Map();
let invitations = []; // Persisted list of invites
let registries = {}; // Persisted registry data: { registryId: { data } }

// Paths for persistence
const USERS_FILE = path.join(__dirname, "data", "users.json");
const INVITES_FILE = path.join(__dirname, "data", "invites.json");
const REGISTRIES_FILE = path.join(__dirname, "data", "registries.json");

/**
 * Persistence Helpers
 */
function loadData() {
  try {
    if (!fs.existsSync(path.join(__dirname, "data"))) {
      fs.mkdirSync(path.join(__dirname, "data"));
    }
    if (fs.existsSync(USERS_FILE)) {
      const data = JSON.parse(fs.readFileSync(USERS_FILE, "utf8"));
      // We only restore the name mapping, socket IDs will be new
      Object.entries(data).forEach(([userId, name]) => {
        activeUsers.set(userId, { socketId: null, displayName: name });
      });
      console.log(`📦 Loaded ${activeUsers.size} users from storage`);
    }
    if (fs.existsSync(INVITES_FILE)) {
      invitations = JSON.parse(fs.readFileSync(INVITES_FILE, "utf8"));
      console.log(`📦 Loaded ${invitations.length} invitations from storage`);
    }
    if (fs.existsSync(REGISTRIES_FILE)) {
      registries = JSON.parse(fs.readFileSync(REGISTRIES_FILE, "utf8"));
      console.log(`📦 Loaded ${Object.keys(registries).length} registries from storage`);
    }
  } catch (err) {
    console.error("❌ Error loading persisted data:", err);
  }
}

function saveUsers() {
  const data = {};
  for (let [userId, userData] of activeUsers.entries()) {
    data[userId] = userData.displayName;
  }
  fs.writeFileSync(USERS_FILE, JSON.stringify(data, null, 2));
}

function saveInvites() {
  fs.writeFileSync(INVITES_FILE, JSON.stringify(invitations, null, 2));
}

function saveRegistries() {
  fs.writeFileSync(REGISTRIES_FILE, JSON.stringify(registries, null, 2));
}

// Initial load
loadData();

io.on("connection", (socket) => {
  console.log("🔌 New socket connected:", socket.id);

  /**
   * Requirement 4: connect_user (Client -> Server)
   * Payload: { userId, displayName }
   */
  socket.on("connect_user", (data) => {
    const { userId, displayName } = data;
    if (!userId || !displayName) return;

    activeUsers.set(userId, {
      socketId: socket.id,
      displayName: displayName
    });

    console.log(`👤 User Connected: ${displayName} (${userId})`);
    saveUsers();

    // Push pending invites (only for registries they haven't joined yet)
    const pending = invitations.filter(inv => {
        if (inv.toUserId !== userId) return false;
        if (inv.registryId && registries[inv.registryId]) {
            const members = registries[inv.registryId].members || [];
            if (members.includes(userId)) return false;
        }
        return true;
    });
    pending.forEach(invite => socket.emit("receive_invite", invite));

    // Send all registries this user is a member of
    const userRegistries = Object.values(registries).filter(reg => 
        reg.ownerId === userId || (reg.members && reg.members.includes(userId))
    );
    if (userRegistries.length > 0) {
        console.log(`📦 Sending ${userRegistries.length} registries to ${displayName}`);
        socket.emit("user_registries", userRegistries);
        // Automatically join rooms for these registries
        userRegistries.forEach(reg => socket.join(reg.id));
    }

    broadcastUsersList();
  });

  /**
   * EVENT: join_registry_room
   * Allows users to receive real-time updates for a specific registry
   */
  socket.on("join_registry_room", (registryId) => {
    socket.join(registryId);
    console.log(`🏠 Socket ${socket.id} joined room: ${registryId}`);
    
    // Add member if not already there
    const userId = getUserIdBySocketId(socket.id);
    const user = activeUsers.get(userId);
    
    if (userId && registries[registryId] && user) {
        if (!registries[registryId].members) registries[registryId].members = [];
        if (!registries[registryId].collaboratorNames) registries[registryId].collaboratorNames = [];
        
        if (!registries[registryId].members.includes(userId)) {
            registries[registryId].members.push(userId);
            registries[registryId].collaboratorNames.push(user.displayName);
            saveRegistries();
            
            // Broadcast updated registry with new collaborator to everyone in the room
            io.to(registryId).emit("registry_updated", registries[registryId]);

            // Clear any pending invites for this user to this registry
            const originalInvCount = invitations.length;
            invitations = invitations.filter(inv => {
                const matchTo = inv.toUserId === userId;
                const matchReg = (inv.registryId || "") === (registryId || "");
                return !(matchTo && matchReg);
            });
            if (invitations.length !== originalInvCount) {
                console.log(`✨ Automatically cleared ${originalInvCount - invitations.length} pending invites for user joining registry`);
                saveInvites();
            }
        }
    }

    if (registries[registryId]) {
        socket.emit("registry_updated", registries[registryId]);
    }
  });

  /**
   * EVENT: sync_registry
   * Called whenever a user modifies their registry.
   * Updates the global state and broadcasts to the room.
   */
  socket.on("sync_registry", (payload) => {
    const { registryId, registryData, userId } = payload;
    if (!registryId || !registryData) return;

    const resolvedUserId = userId || getUserIdBySocketId(socket.id);
    if (!resolvedUserId) return;
    
    // If new registry, set owner and initial members
    if (!registries[registryId]) {
        registryData.ownerId = resolvedUserId;
        registryData.members = [resolvedUserId];
        // Ensure collaboratorNames includes owner
        const user = activeUsers.get(resolvedUserId);
        registryData.collaboratorNames = [user ? user.displayName : "Owner"];
    } else {
        // Keep existing server-managed metadata, fallback to current user if uninitialized
        const user = activeUsers.get(resolvedUserId);
        registryData.ownerId = registries[registryId].ownerId || resolvedUserId;
        registryData.members = registries[registryId].members || [resolvedUserId];
        registryData.collaboratorNames = registries[registryId].collaboratorNames || [user ? user.displayName : "Owner"];
    }

    registries[registryId] = registryData;
    saveRegistries();

    io.to(registryId).emit("registry_updated", registryData);
  });

  /**
   * Requirement 4: get_users (Client -> Server)
   * Returns active users list
   */
  socket.on("get_users", () => {
    socket.emit("users_list", Array.from(activeUsers.entries())
      .filter(([_, data]) => data.socketId !== null) // Only show currently online
      .map(([userId, data]) => ({
        userId,
        displayName: data.displayName
      })));
  });

  /**
   * Requirement 4: send_invite (Client -> Server)
   * Payload: { fromUserId, toUserId, inviteLink }
   */
  socket.on("send_invite", (payload) => {
    const { fromUserId, toUserId, inviteLink, registryId, registryName } = payload;
    const targetUser = activeUsers.get(toUserId);
    const sender = activeUsers.get(fromUserId);

    console.log(`📩 Invite Request: from ${fromUserId} to ${toUserId} for ${registryName || 'room'}`);

    // Check if already a member
    if (registryId && registries[registryId]) {
        const members = registries[registryId].members || [];
        if (members.includes(toUserId)) {
            console.log(`⚠️ User ${toUserId} is already a member of ${registryId}. Skipping invite.`);
            return;
        }
    }

    const inviteData = {
        fromUserId: fromUserId,
        fromDisplayName: sender ? sender.displayName : "Someone",
        inviteLink: inviteLink,
        registryId: registryId,
        registryName: registryName,
        toUserId: toUserId // Store recipient to persist it
    };

    // Persist invitation if not already present
    const exists = invitations.find(inv => 
        inv.fromUserId === fromUserId && 
        inv.toUserId === toUserId && 
        inv.registryId === registryId
    );
    
    if (!exists) {
        invitations.push(inviteData);
        saveInvites();
    }

    if (targetUser && targetUser.socketId) {
      console.log(`✅ Sending real-time invite to ${targetUser.displayName} (${targetUser.socketId})`);
      io.to(targetUser.socketId).emit("receive_invite", inviteData);
    } else {
      console.log(`🕒 User ${toUserId} is offline. Invite saved for later.`);
    }
  });

  /**
   * EVENT: accept_invite
   * Called when a user accepts or ignores an invite.
   */
  socket.on("accept_invite", (payload) => {
    const { fromUserId, toUserId, registryId } = payload;
    console.log(`🗑️ Removing invite: from ${fromUserId} to ${toUserId} for ${registryId || 'no-registry'}`);
    
    const originalCount = invitations.length;
    invitations = invitations.filter(inv => {
        const matchFrom = inv.fromUserId === fromUserId;
        const matchTo = inv.toUserId === toUserId;
        const matchReg = (inv.registryId || "") === (registryId || "");
        return !(matchFrom && matchTo && matchReg);
    });
    
    if (invitations.length !== originalCount) {
        saveInvites();
    }
  });

  /**
   * EVENT: delete_registry
   * Called when a user deletes/leaves a registry.
   */
  socket.on("delete_registry", (payload) => {
    const { registryId, displayName, userId } = payload;
    if (!registryId || !registries[registryId]) return;

    const resolvedUserId = userId || getUserIdBySocketId(socket.id);
    if (!resolvedUserId) return;

    console.log(`🗑️ User ${resolvedUserId} wants to delete/leave registry ${registryId}`);

    let registry = registries[registryId];

    // 1. Remove user from members list
    if (registry.members) {
      registry.members = registry.members.filter(id => id !== resolvedUserId);
    }

    // 2. Remove user's name from collaboratorNames (case-insensitive check)
    let nameToRemove = displayName;
    const user = activeUsers.get(resolvedUserId);
    if (!nameToRemove && user) {
      nameToRemove = user.displayName;
    }

    if (nameToRemove && registry.collaboratorNames) {
      const cleanNameToRemove = nameToRemove.trim().toLowerCase();
      registry.collaboratorNames = registry.collaboratorNames.filter(name => 
        name.trim().toLowerCase() !== cleanNameToRemove
      );
    }

    // 3. Clean up any pending invitations between this user and this registry
    const originalInvCount = invitations.length;
    invitations = invitations.filter(inv => {
      const matchTo = inv.toUserId === resolvedUserId;
      const matchReg = (inv.registryId || "") === (registryId || "");
      return !(matchTo && matchReg);
    });
    if (invitations.length !== originalInvCount) {
      saveInvites();
      console.log(`🧹 Cleaned up ${originalInvCount - invitations.length} pending invites for deleted registry.`);
    }

    // 4. Purge permanently if no members or collaborators are left
    const noMembers = !registry.members || registry.members.length === 0;
    const noCollaborators = !registry.collaboratorNames || registry.collaboratorNames.length === 0;

    if (noMembers || noCollaborators) {
      console.log(`🧹 Registry ${registryId} has no members or collaborators left. Deleting permanently.`);
      delete registries[registryId];
    } else {
      // If the owner left, assign a new owner from the remaining members
      if (registry.ownerId === resolvedUserId) {
        registry.ownerId = registry.members[0];
        console.log(`👑 Owner changed to ${registry.ownerId} for registry ${registryId}`);
      }
      // Broadcast updated registry with the user removed to everyone in the room EXCEPT the leaving user
      socket.to(registryId).emit("registry_updated", registry);
    }

    saveRegistries();

    // Send the updated registries list to the deleting user
    const userRegistries = Object.values(registries).filter(reg => 
      reg.ownerId === resolvedUserId || (reg.members && reg.members.includes(resolvedUserId))
    );
    socket.emit("user_registries", userRegistries);

    // Also leave the room for this registry
    socket.leave(registryId);
  });

  /**
   * Requirement 5: Remove disconnected users automatically
   */
  socket.on("disconnect", () => {
    let disconnectedUserId = null;
    for (let [userId, userData] of activeUsers.entries()) {
      if (userData.socketId === socket.id) {
        disconnectedUserId = userId;
        // Mark as offline but keep identity for persistence
        activeUsers.set(userId, { ...userData, socketId: null });
        break;
      }
    }

    if (disconnectedUserId) {
      console.log(`❌ User Disconnected: ${disconnectedUserId}`);
      // Requirement 5: Broadcast updated user list after disconnect
      broadcastUsersList();
    }
  });
});

/**
 * Helper to broadcast users list to everyone
 */
function broadcastUsersList() {
  const users = Array.from(activeUsers.entries())
    .filter(([_, data]) => data.socketId !== null) // Only broadcast online users
    .map(([userId, data]) => ({
        userId,
        displayName: data.displayName
    }));
  
  io.emit("users_list", users);
  console.log(`📢 Broadcasted users list: ${users.length} users active`);
}

function getUserIdBySocketId(socketId) {
  for (let [userId, userData] of activeUsers.entries()) {
    if (userData.socketId === socketId) return userId;
  }
  return null;
}

app.use(express.json());
app.use("/images", express.static(path.join(__dirname, "images")));

function readJson(fileName) {
  const filePath = path.join(__dirname, "responses", fileName);
  if (!fs.existsSync(filePath)) return {};
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function delayedJson(res, fileName, status = 200, delay = 500) {
  setTimeout(() => {
    res.status(status).json(readJson(fileName));
  }, delay);
}

app.get("/health", (req, res) => {
  res.json({ status: "ok", activeUsersCount: activeUsers.size });
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
  console.log(`🚀 Real-time Backend running on http://0.0.0.0:${PORT}`);
});