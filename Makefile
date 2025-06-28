VPN_MANAGER = ./vpn-manager.sh

COLOR_INFO=\033[1;34m
COLOR_OK=\033[1;32m
COLOR_WARN=\033[1;33m
COLOR_ERROR=\033[1;31m
COLOR_RESET=\033[0m

define run
	@echo -e "$(COLOR_INFO)>>> Running: $1$(COLOR_RESET)"
	@$(1)
	@echo -e "$(COLOR_OK)✔ Done.$(COLOR_RESET)"
endef

install-wireguard:
	$(call run,$(VPN_MANAGER) install-wireguard)

start-wireguard:
	$(call run,$(VPN_MANAGER) start-wireguard)

stop-wireguard:
	$(call run,$(VPN_MANAGER) stop-wireguard)

setup-failover-wireguard:
	$(call run,$(VPN_MANAGER) setup-failover-wireguard)

run-failover-wireguard:
	$(call run,$(VPN_MANAGER) run-failover-wireguard)

install-openvpn:
	$(call run,$(VPN_MANAGER) install-openvpn)

start-openvpn:
	$(call run,$(VPN_MANAGER) start-openvpn)

stop-openvpn:
	$(call run,$(VPN_MANAGER) stop-openvpn)

setup-failover-openvpn:
	$(call run,$(VPN_MANAGER) setup-failover-openvpn)

run-failover-openvpn:
	$(call run,$(VPN_MANAGER) run-failover-openvpn)

status:
	$(call run,$(VPN_MANAGER) status)

help:
	@echo -e "$(COLOR_INFO)Available commands:$(COLOR_RESET)"
	@echo -e "$(COLOR_OK)  make install-wireguard$(COLOR_RESET)        Install WireGuard"
	@echo -e "$(COLOR_OK)  make start-wireguard$(COLOR_RESET)          Start WireGuard"
	@echo -e "$(COLOR_OK)  make stop-wireguard$(COLOR_RESET)           Stop WireGuard"
	@echo -e "$(COLOR_OK)  make setup-failover-wireguard$(COLOR_RESET) Setup WireGuard failover"
	@echo -e "$(COLOR_OK)  make run-failover-wireguard$(COLOR_RESET)   Run WireGuard failover manually"
	@echo -e "$(COLOR_OK)  make install-openvpn$(COLOR_RESET)          Install OpenVPN"
	@echo -e "$(COLOR_OK)  make start-openvpn$(COLOR_RESET)            Start OpenVPN"
	@echo -e "$(COLOR_OK)  make stop-openvpn$(COLOR_RESET)             Stop OpenVPN"
	@echo -e "$(COLOR_OK)  make setup-failover-openvpn$(COLOR_RESET)   Setup OpenVPN failover"
	@echo -e "$(COLOR_OK)  make run-failover-openvpn$(COLOR_RESET)     Run OpenVPN failover manually"
	@echo -e "$(COLOR_OK)  make status$(COLOR_RESET)                   Show status of services"

