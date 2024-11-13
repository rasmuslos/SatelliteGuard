#  Security & Privacy

SatelliteGuard does not collect any personal information. Everything is either stored on device or synced through CloudKit. I don't want to make any guarantees about the the security of either the app or its VPN connection. Form your on opinion and decide if you can trust me. Check the source code. I compiled the gist for your convince below.

### IP-Leaks

The app uses the same backend (WireGuard-GO) as the official app. The integration is virtually the same (providing a Network Extension and letting iOS / WireGuardKit handle the rest), albeit a bit simpler. I can't think of a way leaks could occur, but anything is possible. Some of Apple's own services bypassed VPN connections some time ago, but they vowed to stop.

If you are serious about whatever you are doing, it's probably best to do it on a device where you can manually verify your routing table is configured as expected. SatelliteGuard is only meant for connecting to remote networks, not for applications where security is critical.

### CloudKit

The `Endpoint` model is synced through Apple CloudKit to make configurations available on all of your devices. All properties except the ID (generated randomly by SatelliteGuard) are encrypted. **I would recommend turning on "Advanced data protection" (E2EE)** in the iCloud settings, otherwise Apple may be able to access your configurations.

### On-Device protection

The app requests additional security measures from the system, so files are encrypted after a reboot until the device is unlocked for the first time. The configurations are stored in the `group.io.rfk.SatelliteGuard` app group, to which only SatelliteGuard and it's extensions (e.g. the Network Extensions that handles the VPN connection) have access to.
