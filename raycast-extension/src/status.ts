import { getStatus } from "./cli";
import { showToast, Toast } from "@raycast/api";

export default async function Command() {
  const status = await getStatus();

  if (status.enabled) {
    await showToast({
      style: Toast.Style.Success,
      title: `RayXDR on: ${status.requestedLevel ?? "unknown"}%`,
      message: status.implementationMode,
    });
    return;
  }

  await showToast({
    style: Toast.Style.Success,
    title: "RayXDR off",
    message: status.implementationMode,
  });
}
