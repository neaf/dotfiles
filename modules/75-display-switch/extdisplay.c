// Enable or disable a display by CGDirectDisplayID through the private
// CGSConfigureDisplayEnabled call. Disabled displays stay in CGSGetDisplayList,
// so they can be switched back on (displayplacer cannot find them).
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern CGError CGSGetDisplayList(uint32_t max, CGDirectDisplayID *list, uint32_t *count);
extern CGError CGSConfigureDisplayEnabled(CGDisplayConfigRef cfg, CGDirectDisplayID d, bool enabled);

int main(int argc, char **argv) {
  CGDirectDisplayID all[32], active[32];
  uint32_t nAll = 0, nActive = 0;
  CGSGetDisplayList(32, all, &nAll);
  CGGetOnlineDisplayList(32, active, &nActive);
  if (argc == 2 && !strcmp(argv[1], "list")) {
    for (uint32_t i = 0; i < nAll; i++) {
      int on = 0;
      for (uint32_t j = 0; j < nActive; j++) if (active[j] == all[i]) on = 1;
      printf("%u builtin=%d vendor=%u model=%u serial=%u online=%d\n", all[i], CGDisplayIsBuiltin(all[i]),
             CGDisplayVendorNumber(all[i]), CGDisplayModelNumber(all[i]), CGDisplaySerialNumber(all[i]), on);
    }
    return 0;
  }
  if (argc == 3 && (!strcmp(argv[1], "on") || !strcmp(argv[1], "off"))) {
    CGDirectDisplayID id = (CGDirectDisplayID)atoi(argv[2]);
    CGDisplayConfigRef cfg;
    if (CGBeginDisplayConfiguration(&cfg) != kCGErrorSuccess) return 1;
    CGSConfigureDisplayEnabled(cfg, id, !strcmp(argv[1], "on"));
    return CGCompleteDisplayConfiguration(cfg, kCGConfigurePermanently) == kCGErrorSuccess ? 0 : 1;
  }
  fprintf(stderr, "usage: extdisplay list | on ID | off ID\n");
  return 2;
}
