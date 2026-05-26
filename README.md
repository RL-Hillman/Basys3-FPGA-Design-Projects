# FPGA_Basys3_VHDL_Projects

# Real-Hardware Conversion Scaffold

**Reference only — this is NOT built.** `drones.c` is the *simulation* (all state in
kernel memory). This doc sketches what the driver would become if it drove **real
drone hardware** over a memory-mapped register block, filling in the part the inline
`REAL HW:` comments in `drones.c` point at but don't provide: the device binding,
register map, and `regs_base` setup.

> Every register name/offset/command code below is a **placeholder**. On real
> silicon they come from the device's **datasheet**.

---

## 1. What changes conceptually

| Simulation (`drones.c` today) | Real hardware |
|---|---|
| Pure char device; `skyport_init()` manually allocates dev numbers | A **`platform_driver`** (or `pci_driver`) that **binds** to a device and runs `probe()` |
| State kept in the struct; User Space writes position/battery via `SET_TELEMETRY` | Sensors are **read from registers**; `SET_TELEMETRY` goes away (data flow inverts) |
| `drone_state = HOVERING;` etc. | `writel(CMD_HOVER, regs_base + COMMAND_REG);` |
| `get_random_u32()` fakes altitude/speed/weight | `readl(regs_base + ALTIMETER_REG)` etc. |
| No interrupts | Likely an **IRQ** for arrival/error events instead of polling |

---

## 2. Register map (from the datasheet — placeholders here)

```c
/* Read-only sensor registers */
#define DRONE_STATUS_REG     0x00   /* flight status / flags          */
#define DRONE_GPS_X_REG      0x04   /* current position X             */
#define DRONE_GPS_Y_REG      0x08   /* current position Y             */
#define DRONE_ALTITUDE_REG   0x0C   /* altimeter, metres              */
#define DRONE_SPEED_REG      0x10   /* speedometer, km/h              */
#define DRONE_BATTERY_REG    0x14   /* battery, percent               */
#define DRONE_WEIGHT_REG     0x18   /* package weight sensor, grams   */

/* Write registers */
#define DRONE_COMMAND_REG    0x1C   /* write a CMD_* code below       */
#define DRONE_NAV_X_REG      0x20   /* target X for navigation        */
#define DRONE_NAV_Y_REG      0x24   /* target Y for navigation        */

/* Command codes written to DRONE_COMMAND_REG */
#define CMD_EMERGENCY_LAND   0x01
#define CMD_HOVER            0x02
#define CMD_GOTO_CHARGER     0x03
#define CMD_ABORT_MISSION    0x04
#define CMD_START_MISSION    0x05
#define CMD_GRIP_PACKAGE     0x06
#define CMD_RELEASE_PACKAGE  0x07
#define CMD_FLY_TO_PICKUP    0x08
#define CMD_FLY_TO_DROPOFF   0x09
```

---

## 3. Struct — add the mapped register base

```c
struct skyport_drone {
    /* ... same mission params / flags as the simulation ... */

    void __iomem *regs_base;   /* mapped MMIO base, set in probe() */

    struct mutex  lock;
    struct cdev   cdev;
};
```

---

## 4. probe() / remove() — replaces the manual setup in skyport_init/exit

```c
#include <linux/platform_device.h>
#include <linux/io.h>                  /* ioremap, readl, writel */
#include <linux/mod_devicetable.h>     /* of_device_id */

static int skyport_probe(struct platform_device *pdev)
{
    struct skyport_drone *drone;
    struct resource *res;

    drone = devm_kzalloc(&pdev->dev, sizeof(*drone), GFP_KERNEL);
    if (!drone)
        return -ENOMEM;

    /* Grab the device's register block and map it into kernel address space. */
    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    drone->regs_base = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(drone->regs_base))
        return PTR_ERR(drone->regs_base);   /* maps + request_mem_region in one */

    mutex_init(&drone->lock);
    platform_set_drvdata(pdev, drone);

    /* Then create the cdev / "/dev/skyport_droneX" node, as skyport_init() does. */

    /* Optional: request an IRQ for arrival/error events:
     *   int irq = platform_get_irq(pdev, 0);
     *   devm_request_irq(&pdev->dev, irq, skyport_isr, 0, "skyport", drone);
     */
    return 0;
}

static int skyport_remove(struct platform_device *pdev)
{
    /* devm_* allocations and the ioremap are released automatically.
     * Just tear down the cdev / device node here. */
    return 0;
}
```

---

## 5. Binding + module registration (device tree)

```c
static const struct of_device_id skyport_of_match[] = {
    { .compatible = "skyport,drone" },
    { }
};
MODULE_DEVICE_TABLE(of, skyport_of_match);

static struct platform_driver skyport_driver = {
    .probe  = skyport_probe,
    .remove = skyport_remove,
    .driver = {
        .name           = "skyport_drone",
        .of_match_table = skyport_of_match,
    },
};
module_platform_driver(skyport_driver);   /* replaces module_init/module_exit */
```

The kernel calls `probe()` when a device node whose `compatible` matches
`"skyport,drone"` appears (from the board's device tree).

---

## 6. How the handlers change

Each `REAL HW:` comment in `drones.c` becomes a register access on `regs_base`:

```c
/* HOVER */
writel(CMD_HOVER, drone->regs_base + DRONE_COMMAND_REG);

/* GO_TO_CHARGER x y */
writel(charger_x, drone->regs_base + DRONE_NAV_X_REG);
writel(charger_y, drone->regs_base + DRONE_NAV_Y_REG);
writel(CMD_GOTO_CHARGER, drone->regs_base + DRONE_COMMAND_REG);

/* read() telemetry — read the live sensors instead of faking them */
drone->current_x = readl(drone->regs_base + DRONE_GPS_X_REG);
drone->current_y = readl(drone->regs_base + DRONE_GPS_Y_REG);
drone->altitude  = readl(drone->regs_base + DRONE_ALTITUDE_REG);
drone->speed     = readl(drone->regs_base + DRONE_SPEED_REG);
drone->battery_percent = readl(drone->regs_base + DRONE_BATTERY_REG);

/* PICKING_PACKAGE — read the weight sensor */
drone->package_weight = readl(drone->regs_base + DRONE_WEIGHT_REG);
writel(CMD_GRIP_PACKAGE, drone->regs_base + DRONE_COMMAND_REG);
```

**`SET_TELEMETRY` disappears entirely** — position and battery are read from the
device, not written by User Space.

---

## 7. Still not free — the remaining real work

Even with the above scaffold, a production driver needs:

- **Real register values** from the datasheet (offsets + command codes).
- **IRQ handling** — an interrupt handler for arrival/error/low-battery events, instead of polling status every read.
- **MMIO ordering** — `readl`/`writel` are ordered, but mixing with DMA or needing explicit barriers (`wmb()`/`rmb()`) is device-specific.
- **Hardware error handling** — timeouts, device-removed, bad status reads.
- **Possibly DMA** if telemetry is bulk-transferred rather than per-register.

So this scaffold maps the *structure* of the conversion; the datasheet + IRQ/DMA
work would still be the bulk of a real driver.
