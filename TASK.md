Review the  nix configuration in this directory. Of particular note is that I have a system/ and a home/ section, each of which contains host-specific configuration, and then common configuration which is further subdivided into required and modules. All hosts import all of the required modules, then some hosts enable some things in the modules/ directory. 

Our goal will be to transform this nix configuration into a new format. The goal here is to remove the structural distinction between `modules` and `required`. In addition, we want to remove the structural distinction between `home` and `system`. As it stands right now, there is some awkwardness in certain things (e.g. hyprland stuff) being configured in both home and system, and the two configurations don't really talk to each other appropriately. 

Of particular importance is the use of lib.custom.scanPaths. This means that simply adding a file into one of the required or modules directories auto-imports it into all system configurations. I Want to maintain this functionality.


My desired format is as follows


hosts/
    standalone/
        # replicate current home-manager-only setup
        default.nix
    icicle/
        hardware-configuration.nix
        default.nix
        disks.nix
    midnight/
        hardware-configuration.nix
        default.nix
        disks.nix
    nimbus/
        hardware-configuration.nix
        default.nix
        disks.nix

modules/
    features/
        apps/
            default.nix # lib.custom.scanPaths import everything
            brave.nix
            discord.nix
            dolphin.nix
            element-desktop.nix
            librewolf.nix
            ... other apps from gui-apps.nix
            audacity.nix
            musescore.nix
            reaper.nix

            nixvim/
                ... nixvim config

            opencode/
            kitty.nix
            ... review config for any other apps. each distinct app should get its own file, which is not how i have it done right now

            
        desktop/
            default.nix # lib.custom.scanPaths import everything and shared desktop configuration that COULD be reused across desktops, like idle behavior configuration, the theme.nix stuff
            hyprland/
                hypridle.nix # should probably read from cfg.custom.desktop.idle.{dim,lock,sleep}
                default.nix # contains system/common/modules/hyprland/hyprland.nix and home/common/modules/hyprland/hyprland.nix configuration together
                ... various hyprland home modules
            gnome/ # future development, dont implement now 
            
        hardware/
            default.nix # lib.custom.scanPaths import everything
            audio.nix
            bluetooth.nix
            gpu/
                default.nix # lib.custom.scanPaths import everything
                intel.nix
                nvidia.nix
            ups.nix
            seagate-hdd.nix
            wifi.nix

        meta/
            default.nix # lib.custom.scanPaths import everything
            auto-upgrade.nix
            impermanence.nix
            parthiv.nix # will this be needed??
            sops.nix
            unfree.nix

        networking/
            default.nix # lib.custom.scanPaths import everything
            sshd.nix
            tailscale.nix
            wake-on-lan.nix


        selfhosted/
            default.nix # lib.custom.scanPaths import everything, core selfhosted fucntionality as it is now
            ... all selfhosted stuff

        storage/
            default.nix # lib.custom.scanPaths import everything
            samba.nix
            restic.nix
            zfs.nix


    manifests/
        required.nix # enables all required stuff (whatever was in home/common/required and system/common/required)
        desktop-environment.nix # enables hyprland and all gui-apps from old gui-apps.nix
        server.nix # enables server related stuff (right now, just sshd)
        sound-engineering.nix # enables all sound-engineering apps

Note how there is no longer a distinction between home/system, and modules/required! 

Existing lib/ and scripts/ and tools/ can be kept as is.


Now we have to figure out how these leaf files look. We have basically three categories:

1. Feature files. These are the ones I am least sure of how to make them look. At a high level, each feature should be a nixos module that has an enable option at the path defined by its directory path. For example, `features/hardware/gpu/nvidia.nix should have a `custom.features.hardware.gpu.nvidia.enable = mkEnableOption ...`. It could also have other options within it as needed, like the cudaCapability etc. 

What I'm not sure about is then how we merge both nixos and home config. What I want is that both the nixos config and the home config can read from the same combined custom.features.<feature_path>.* options, to configure both home and system-level config completely transparently. These should all get exposed back up somehow, I'm not sure how this looks. 

My dream would be for us to make some lib.custom.mkFeature which can automatically determine its path. Then it takes in `extraOptions ? null` and create options at that path, and takes in `systemConfig ? null` and `homeConfig ? null`. Then we can just make these features by keeping all the boilerplate in `lib.custom.mkFeature` and just allowing each file to declare the relevant extraOptions, systemConfig, and homeConfig (all of which are optional). I'm not sure if this is at all possible.


2. Manifest files. These should be fairly simple. They should have their own enable flag at `custom.manifests.<manifest>.enable`. When enabled, would just enable various features using `custom.<feature_path>.enable = lib.mkDefault true`. They can also configure sensible defaults for non-enable options if it makes sense to do so. They can also assert some things; right now, all I can think of is that the required module should assert that it's enabled, for example. However, it should still use nix's mkEnableOption (which defaults to false) because I want each host-specific file to actually list the required manifest as enabled, rather than it being a morepassive thing. 

3. Host files. Leave disks.nix and hardware-configuration.nix exactly as is; these are more or less completely static files that are somewhat generated. But we should simplify the host specific-files. For default.nix, I want this to look very much like a manifest. It should contain some minimal boilerplate at the top (or better yet, we should create a lib.custom.mkHost for this boilerplate. All I can think  of here is to just have the boilerplate code that imports the disks.nix and hardware-configuration.nix. Then maybe mkHost takes in a single argument which is the custom configuration:

e.g. for icicle (incomplete):

```
custom = {
    manifests = {
        required.enable = true;
        desktop-environment.enable = true;
        sound-engineering.enable = true;
    };

    features = {
        desktop.idle = {
            dim = 15;
            lock = 20;
            sleep = 30;
        };

        opencode.enable = true;

        wifi = {
            enable = true;
            driver = "mt7921e";
        };
    };

};

```

This looks super clean and is a very clear and obvious list of how this system is configured! It doesn't matter that some of the desktop config is in home, some is in system, opencode is in home, wifi is in system, etc. It's completely transparent at the system level configuration. This works because we assume all of these machines will just have one user. 


NOTE: right now, the selfhosted code is totally spaghetti and breaks the abstraction I've requested. For now, we can just have midnight/nimbus import the selfhosted code and let the selfhosted code handle splitting itself amongst the two. I'll fix this later.

