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
  usersWithWork = users ++ [{
    username = "alexbn-work";
    homeDirectory = "/home/alexbn-work";
  }];
  macUsers = [{
    username = "alexbn";
    homeDirectory = "/Users/alexbn";
  }];
in { inherit users usersWithGuests usersWithWork macUsers; }
