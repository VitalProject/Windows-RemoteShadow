# Windows RemoteShadow
 
## Environment Configuration

- Make sure that RDP is enable in settings, for security use network level AUTH
![Image of Remote Access](https://github.com/Mentaleak/Windows-RemoteShadow/blob/master/docs/Remote_access.png?raw=true)
- Then configure the machines Terminal Services settings “HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services” 
 - This is probably easiest done by GPO
   - Computer Configuration\Administrative Templates\Windows Components\Remote Desktop Services\Remote Desktop Session Host\Connections\Set rules for remote control of Remote Desktop Services user sessions
![Image of GPO for RDP](https://github.com/Mentaleak/Windows-RemoteShadow/blob/master/docs/GroupPolicy.png?raw=true)
 - The options are:
      1. No remote control allowed: Disallows an administrator to use remote control or view a remote user session.
      2. Full Control with user's permission: Allows the administrator to interact with the session, with the user's consent.
      3. Full Control without user's permission: Allows the administrator to interact with the session, without the user's consent.
      4. View Session with user's permission: Allows the administrator to watch the session of a remote user with the user's consent. 
      5. View Session without user's permission: Allows the administrator to watch the session of a remote user without the user's consent.
 
- Mmake sure that the windows firewalls are configured to allow for RPC
  - See the citated articles on RPC Firewall

## Windows-RemoteShadow Tool
 This tool allows you to enter the hostname or browse the domain for a machine you would like to shadow
 ![Image of Util](https://github.com/Mentaleak/Windows-RemoteShadow/blob/master/docs/Utility.png?raw=true)
 The browse feature detects the current dowmain and loads computer objects in along with FQDN and one level of OU information
 ![Image of Util Browse](https://github.com/Mentaleak/Windows-RemoteShadow/blob/master/docs/Select%20Macchine%20Browse.png?raw=true)


## RDP Shadow Issues
- Multiple concurrent local logins.
- Shadowing requires specification of the current session.
  -	If there are multiple concurrent sessions on a workstation then you need to specify which one to connect to.
  - Options:
    1.	Use GPO to limit concurrent connections
    2.	Enable WSManagement service so that you can detect concurrent connections. 

The code for detecting concurrent sessions is already in source and just not in the GUI at this time.






## Citations
- https://community.spiceworks.com/topic/1974807-remote-assistance-take-control-without-user-interaction?page=1#entry-6722269
- https://community.spiceworks.com/topic/1974807-remote-assistance-take-control-without-user-interaction
- https://help.nerdio.net/hc/en-us/articles/360027508512-How-do-I-shadow-a-specific-user-s-desktop-on-a-multi-user-session-host-
- https://community.spiceworks.com/how_to/136210-use-mstsc-as-a-remote-viewer-controller
- https://help.f-secure.com/product.html?business/radar/3.0/en/task_634DEC31FB56434D8692BFEACB77829D-3.0-en
- https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/create-inbound-rules-to-support-rpc
- https://superuser.com/questions/833963/is-there-a-way-to-limit-windows-so-only-one-user-can-be-logged-on-at-a-time-win
