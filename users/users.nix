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
  macUsers = [{
    username = "alexbn";
    homeDirectory = "/Users/alexbn";
  }];
in { inherit users usersWithGuests macUsers; }
