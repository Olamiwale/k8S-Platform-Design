const express = require("express");
const os = require("os");

const app = express();

app.get("/", (req, res) => {
  res.json({
    message: "Kubernetes Platform Application",
    status: "running",
    hostname: os.hostname()
  });
});

app.get("/health", (req, res) => {
  res.status(200).send("Healthy");
});

app.get("/api", (req, res) => {
  res.json({ platform: "AWS EKS", environment: "dev" });
});

app.listen(3000, "0.0.0.0", () => {
  console.log("Application running on port 3000");
});