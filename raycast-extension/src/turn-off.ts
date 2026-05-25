import { runCli } from "./cli";

export default async function Command() {
  await runCli(["off"], "Extra Brightness off");
}
