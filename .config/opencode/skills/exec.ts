import { execSync } from "node:child_process";

export default {
  name: "exec",
  description: "Execute shell commands",
  run({ command }) {
    return execSync(command, { encoding: "utf8" });
  },
};
