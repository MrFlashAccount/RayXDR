import { environment, showToast, Toast } from "@raycast/api";
import { execFile } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const targetLevel = "150";
const cliCandidates = [
  path.resolve(environment.assetsPath, "bin", "rayxdr"),
  path.resolve(process.cwd(), "assets", "bin", "rayxdr"),
  path.resolve(__dirname, "..", "assets", "bin", "rayxdr"),
  path.resolve(__dirname, "..", "..", "assets", "bin", "rayxdr"),
];

function getCliPath(): string {
  const cliPath = cliCandidates.find((candidate) => fs.existsSync(candidate));

  if (!cliPath) {
    throw new Error("Bundled rayxdr CLI missing. Run `npm run build:cli` from raycast-extension.");
  }

  return cliPath;
}

export function getTargetLevel(): string {
  return targetLevel;
}

export type ExtraBrightnessStatus = {
  enabled: boolean;
  implementationMode: string;
  requestedLevel?: number;
  unsupportedReason?: string;
  updatedAt?: string;
};

export async function runCliRaw(args: string[]): Promise<string> {
  const cliPath = getCliPath();
  const { stdout } = await execFileAsync(cliPath, args);
  return stdout.trim();
}

export async function getStatus(): Promise<ExtraBrightnessStatus> {
  const output = await runCliRaw(["status", "--json"]);
  return JSON.parse(output) as ExtraBrightnessStatus;
}

export async function runCli(args: string[], successTitle?: string): Promise<void> {
  try {
    const output = await runCliRaw(args);
    await showToast({
      style: Toast.Style.Success,
      title: successTitle || output || "Done",
    });
  } catch (error) {
    const message =
      error instanceof Error && "stderr" in error && typeof error.stderr === "string" && error.stderr.trim()
        ? error.stderr.trim()
        : error instanceof Error
          ? error.message
          : String(error);
    await showToast({
      style: Toast.Style.Failure,
      title: "RayXDR failed",
      message,
    });
  }
}
