import { getStatus, getTargetLevel, runCli } from "./cli";

export default async function Command() {
  const status = await getStatus();

  if (status.enabled) {
    await runCli(["off"], "Extra Brightness off");
    return;
  }

  const level = getTargetLevel();
  await runCli(["on", level], `Extra Brightness on: ${level}%`);
}
