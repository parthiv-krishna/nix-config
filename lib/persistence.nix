_: {
  # creates persistent directory config for impermanence
  mkPersistentSystemDir =
    {
      directory,
      user ? "root",
      group ? user,
      mode ? "0700",
    }:
    {
      environment.persistence."/persist/system".directories = [
        {
          inherit
            directory
            user
            group
            mode
            ;
        }
      ];
    };
}
