extends Node
# P1X Godot Multiplayer Server

export var PORT = 9666
var _server = WebSocketServer.new()
var players_list = []

func _ready():
	lprint("Welcome to the TCPServer. By P1X. Visit https://p1x.")
	lprintnb("Connecting events...")
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	_server.connect("data_received", self, "_on_data")
	lprint("...OK")
	lprintnb("Starting server...")
	var err = _server.listen(PORT)
	if err != OK:
		lprint("...ERROR")
		lprint("Unable to start server")
		set_process(false)
	else:
		lprint("...OK")
		lprint("Server started at port " + str(PORT))

func _connected(id, proto):
	lprint("Player %d connected." % [id])
	add_player(id)
	
func _close_request(id, code, reason):
	lprint("Player %d disconnecting with code: %d, reason: %s" % [id, code, reason])

func _disconnected(id, was_clean = false):
	lprint("Player %d disconnected, clean: %s" % [id, str(was_clean)])
	remove_player(id)
	for player in players_list:
		var payload = 'DIS/%s' % [id]
		_server.get_peer(player.id).put_packet(payload.to_utf8())

func _process(delta):
	_server.poll()

func _exit_tree():
	_server.stop()
	
	



func _on_data(id):
	var payload
	var pkt = _server.get_peer(id).get_packet().get_string_from_utf8().split("/", true)
	lprint("Got data from player %d: %s" % [id, pkt[0]])
	
	if pkt[0] == "JOIN":
		payload = 'YOUR_ID/%s' % id
		_server.get_peer(id).put_packet(payload.to_utf8())
		
		payload = 'NEW_JOIN/%s' % [id]
		for player in players_list:
			if player.id != id:
				_server.get_peer(player.id).put_packet(payload.to_utf8())
		
	if pkt[0] == "POS":
		for player in players_list:
			payload = 'POS/%s/%s' % [id, pkt[1]]
			update_last_pos(id, pkt[1])
			if player.id != id:
				_server.get_peer(player.id).put_packet(payload.to_utf8())

	if pkt[0] == "GET_PLAYERS_LIST":
		for player in players_list:
			if player.id != id:
				payload = 'NEW_JOIN/%s/%s' % [player.id, player.last_position]
				_server.get_peer(id).put_packet(payload.to_utf8())
			
	
	
func add_player(id):
	var new_player = {
		'id': id,
		'name': 'annonymous',
		'last_pos': '0.0,0.0,0.0',
		'flashlight': false
	}
	players_list.append(new_player)
	refresh_player_list()
	
func remove_player(id):
	var f = 0
	for p in players_list:
		if p.id == id:
			players_list.remove(f)
	refresh_player_list()
	
func update_last_pos(id, pos):
	for p in players_list:
		if p.id == id:
			p.last_position = pos

func lprint(message):
	print(message)
	$GUI/panels/logs/log.add_text(message + '\n')

func lprintnb(message):
	$GUI/panels/logs/log.add_text(message)
	
func refresh_player_list():
	$GUI/panels/right/info/players.clear()
	var i = 1
	$GUI/panels/right/info/players.add_text("Players:\n\n")
	for player in players_list:
		$GUI/panels/right/info/players.add_text("%s> %s (%s)\n" % [i, player.name, player.id])
		i += 1
