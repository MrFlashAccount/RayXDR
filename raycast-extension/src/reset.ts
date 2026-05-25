import { runCli } from "./cli";

export default async function Command() {
  await runCli(["reset"]);
}
