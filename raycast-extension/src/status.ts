import { getStatus } from "./cli";
import { showToast, Toast } from "@raycast/api";

export default async function Command() {
  const status = await getStatus();

  if (status.enabled) {
    await showToast({
      style: Toast.Style.Success,
      title: `Extra Brightness on: ${status.requestedLevel ?? "unknown"}%`,
      message: status.implementationMode,
    });
    return;
  }

  await showToast({
    style: Toast.Style.Success,
    title: "Extra Brightness off",
    message: status.implementationMode,
  });
}
