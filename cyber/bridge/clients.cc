/**
 * Copyright (c) 2019 LG Electronics, Inc.
 *
 * This software contains code licensed as described in LICENSE.
 *
 */
#include "cyber/bridge/clients.h"

#include <memory>

#include "cyber/bridge/client.h"

Clients::Clients() {}

Clients::~Clients() {}

void Clients::start(std::shared_ptr<Client> client) {
  clients.insert(client);
  client->start();
}

void Clients::stop(std::shared_ptr<Client> client) {
  clients.erase(client);
  client->stop();
}

void Clients::stop_all() {
  for (auto& client : clients) {
    client->stop();
  }
  clients.clear();
}
