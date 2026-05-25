import { getTargetLevel, runCli } from "./cli";

export default async function Command() {
  const level = getTargetLevel();
  await runCli(["on", level], `Extra Brightness on: ${level}%`);
}
