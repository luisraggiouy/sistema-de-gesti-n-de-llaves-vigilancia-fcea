// Declare the kioskModeAPI interface for TypeScript
declare global {
  interface Window {
    kioskModeAPI?: {
      usbDrives: Array<{
        mountPoint: string;
        label: string;
      }>;
      writeFile: (path: string, content: string) => Promise<void>;
    };
  }
}

export {}; // Ensure this file is treated as a module