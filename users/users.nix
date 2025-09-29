{ ... }:
let
  users = [{
    username = "alexbn";
    homeDirectory = "/home/alexbn";
  }];
  usersWithGuests = users ++ [{
    username = "guest";
    homeDirectory = "/home/guest";
  }];
in { inherit users usersWithGuests; }
