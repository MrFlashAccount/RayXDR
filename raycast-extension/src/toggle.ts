import { getStatus, getTargetLevel, runCli } from "./cli";

export default async function Command() {
  const status = await getStatus();

  if (status.enabled) {
    await runCli(["off"], "RayXDR off");
    return;
  }

  const level = getTargetLevel();
  await runCli(["on", level], `RayXDR on: ${level}%`);
}
