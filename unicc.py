#! /usr/bin/python3

#### universal compiler compiler

import os
import sys

class POINTER:
	def __repr__(self):
		return '*'
POINTER = POINTER()

class Grammar:
	def __init__(self):
		self.next_value = 256
		self.tokens = {}
		self.ruleset = {}
		self.rules = []
		self.actions = []
		self.gotos = []
		self.states = []
		self.globals = {}

		self.token_names = {}
		self.preamble = ""
		self.postamble = ""

GRAMMAR = Grammar()

class Terminal:
	def __init__(self, name, value = None):
		global GRAMMAR
		self.name = name
		if value is None:
			self.value = GRAMMAR.next_value
			GRAMMAR.next_value += 1
		else:
			self.value = value
		GRAMMAR.tokens[self.value] = self
		GRAMMAR.token_names[self.name] = self

	def is_terminal(self):
		return True

	def __repr__(self):
		return self.name

class NonTerminal:
	def __init__(self, name, value = None):
		global GRAMMAR
		self.name = name
		if value is None:
			self.value = GRAMMAR.next_value
			GRAMMAR.next_value += 1
		else:
			self.value = value
		GRAMMAR.tokens[self.value] = self
		GRAMMAR.token_names[self.name] = self

	def is_terminal(self):
		return False

	def __repr__(self):
		return self.name

	def add_rule(self, *tokens, action = ""):
		global GRAMMAR
		if self not in GRAMMAR.ruleset:
			GRAMMAR.ruleset[self] = set()
		rule = Rule(*tokens, action = action, production = self)
		GRAMMAR.ruleset[self].add(rule)
		return rule

class Rule:
	def __init__(self, *tokens, action = "", production = None):
		global GRAMMAR
		self.production = production
		self.tokens = tokens
		self.number = len(GRAMMAR.rules)
		self.action = action.lstrip('\n').rstrip()
		GRAMMAR.rules.append(self)

	def __repr__(self):
		return repr(self.tokens)

	def __hash__(self):
		return self.number

class Item:
	def __init__(self, rule, offset = 0):
		self.rule = rule
		self.offset = offset

	def __repr__(self):
		return repr(self.rule.tokens[:self.offset] + (POINTER,) + self.rule.tokens[self.offset:])

	def __str__(self):
		return ' '.join(map(repr, self.rule.tokens[:self.offset] + (POINTER,) + self.rule.tokens[self.offset:]))

	def __eq__(self, other):
		return type(other) is Item and (self.rule, self.offset) == (other.rule, other.offset)

	def __hash__(self):
		return hash((self.rule, self.offset))

	def next(self):
		if self.offset < len(self.rule.tokens):
			return self.rule.tokens[self.offset]
		else:
			return None

	def advance(self, token):
		if token == self.next():
			return Item(self.rule, self.offset + 1)
		else:
			return None

class ItemSet:
	def __init__(self, *items):
		self.items = set(items)

	def __repr__(self):
		return repr(self.items)

	def copy(self):
		return ItemSet(*self.items)

	def next_tokens(self):
		next_tokens = set()
		for item in self.items:
			next_tokens.add(item.next())
		return next_tokens

	def close(self):
		global GRAMMAR
		check_items = self.items
		while len(check_items) != 0:
			new_items = set()
			for item in check_items:
				next_token = item.next()
				if type(next_token) is NonTerminal:
					for rule in GRAMMAR.ruleset[next_token]:
						new_item = Item(rule)
						if new_item not in self.items:
							new_items.add(new_item)
			self.items.update(new_items)
			check_items = new_items
		return self

	def advance(self, token):
		next_items = []
		for item in self.items:
			next_item = item.advance(token)
			if next_item is not None:
				next_items.append(next_item)
		return ItemSet(*next_items)

	def terminate(self):
		rules = set()
		for item in self.items:
			if item.next() is None:
				rules.add(item.rule)
		return rules

	def __eq__(self, other):
		return type(other) in {ItemSet, State} and self.items == other.items

class State:
	def __init__(self, *items):
		global GRAMMAR
		if len(items) == 1 and type(items[0]) in {ItemSet, State}:
			self.items = items[0].items.copy()
		else:
			self.items = set(items)
		self.number = len(GRAMMAR.states)
		GRAMMAR.states.append(self)

	def __eq__(self, other):
		#print("?", other.items, "==", self.items)
		return type(other) in {ItemSet, State} and self.items == other.items

	def __hash__(self):
		return self.number

	def __repr__(self):
		return repr(self.items)

#### Parser grammar

IDENTIFIER = Terminal('IDENTIFIER')
CHARACTER = Terminal('CHARACTER')
MARK = Terminal('MARK') # %%
CCODE = Terminal('CCODE') # %{ %}
TOKEN = Terminal('TOKEN') # %token
START = Terminal('START') # %start
EMPTY = Terminal('EMPTY') # %empty
DEFINE = Terminal('DEFINE') # %define
ACTION = Terminal('ACTION') # { }
file = NonTerminal('file')
definitions = NonTerminal('definitions')
definition = NonTerminal('definition')
name_list = NonTerminal('name_list')
rules = NonTerminal('rules')
rule_definition = NonTerminal('rule_definition')
rule_body = NonTerminal('rule_body')
rule = NonTerminal('rule')
tail = NonTerminal('tail')

START_NAME = None

class Action:
	def __init__(self, code):
		self.code = code

def define_start(name):
	global START_NAME
	START_NAME = get_token(name)

def define_token(*names):
	for name in names:
		Terminal(name)

def define_global(name, value):
	global GRAMMAR
	assert name not in GRAMMAR.globals
	GRAMMAR.globals[name] = value

def define_rule(name, *cases):
	rule = get_token(name)
	for _case in cases:
		if len(_case) > 0 and type(_case[-1]) is Action:
			rule.add_rule(*_case[:-1], action = _case[-1].code)
		else:
			rule.add_rule(*_case)

def get_token(name):
	global GRAMMAR
	if name not in GRAMMAR.token_names:
		return NonTerminal(name)
	else:
		return GRAMMAR.token_names[name]

def add_preamble(text):
	GRAMMAR.preamble += text

def add_postamble():
	global LAST, INPUT_FILE
	if LAST is not None:
		GRAMMAR.postamble = LAST
	GRAMMAR.postamble += INPUT_FILE.read()

file.add_rule(definitions, MARK, rules, tail)
definitions.add_rule()
definitions.add_rule(definitions, definition)
definition.add_rule(CCODE).action = lambda *args: add_preamble(args[0])
definition.add_rule(TOKEN, name_list).action = lambda *args: define_token(*args[1])
definition.add_rule(START, IDENTIFIER).action = lambda *args: define_start(args[1])
definition.add_rule(DEFINE, IDENTIFIER, ACTION).action = lambda *args: define_global(args[1], args[2])
name_list.add_rule(IDENTIFIER)
name_list.add_rule(name_list, IDENTIFIER)
rules.add_rule(rule_definition)
rules.add_rule(rules, rule_definition)
rule_definition.add_rule(IDENTIFIER, ':', rule_body, ';').action = lambda *args: define_rule(args[0], *args[2])
rule_body.add_rule(rule)
rule_body.add_rule(rule_body, '|', rule).action = lambda *args: args[0] + [args[2]]
rule.add_rule().action = lambda *args: []
rule.add_rule(rule, EMPTY).action = lambda *args: args[0]
rule.add_rule(rule, IDENTIFIER).action = lambda *args: args[0] + [get_token(args[1])]
rule.add_rule(rule, CHARACTER).action = lambda *args: args[0] + [args[1]]
rule.add_rule(rule, ACTION).action = lambda *args: args[0] + [Action(args[1])] # TODO
tail.add_rule()
tail.add_rule(MARK).action = lambda *args: add_postamble()

def compile_grammar(grammar, start):
	EOF = Terminal('_EOF', 0)
	ACCEPT = NonTerminal('ACCEPT', 1)
	START = ACCEPT.add_rule(start, EOF)

	itemset = ItemSet(Item(START))
	itemset.close()
	State(itemset)
	check_itemsets = [itemset]
	new_itemsets = []

	while len(check_itemsets) != 0:
		new_itemsets = []
		for itemset in check_itemsets:
			for token in itemset.next_tokens():
				if token is not None:
					itemset1 = itemset.advance(token)
					itemset1.close()
					if itemset1 not in grammar.states:
						State(itemset1)
						new_itemsets.append(itemset1)
		check_itemsets = new_itemsets

	for i in range(len(grammar.states)):
		grammar.actions.append({})
		grammar.gotos.append({})
		itemset = ItemSet(*grammar.states[i].items)

		for token in itemset.next_tokens():
			if token is None:
				rules = itemset.terminate()
				assert len(rules) == 1
				rule = next(iter(rules))
				if rule == START:
					action = ("ACCEPT", None)
				else:
					action = ("APPLY", rule.number)
				grammar.actions[-1][-1] = action
			else:
				next_itemset = itemset.advance(token)
				next_itemset.close()
				if type(token) is NonTerminal:
					value = ord(token) if type(token) is str else token.value
					grammar.gotos[-1][value] = grammar.states.index(next_itemset)
				else:
					value = ord(token) if type(token) is str else token.value
					grammar.actions[-1][value] = ("SHIFT", grammar.states.index(next_itemset))

		if -1 not in grammar.actions[-1]:
			grammar.actions[-1][-1] = ("ERROR", None)

compile_grammar(GRAMMAR, file)

#### Interpret grammar (needed to parse yacc file)

LAST = None
YYLVAL = None
MARKCOUNT = 0
INPUT_FILE = None
def yylex():
	global LAST, YYLVAL, MARKCOUNT, INPUT_FILE
	if MARKCOUNT == 2:
		# pretend the file is terminated
		return 0

	if LAST is not None:
		c = LAST
		LAST = None
	else:
		c = INPUT_FILE.read(1)

	while c == ' ' or c == '\t' or c == '\n':
		c = INPUT_FILE.read(1)
	if c == '':
		return 0
	#elif '0' <= c and c <= '9':
	#	d = 0
	#	while '0' <= c and c <= '9':
	#		d = 10 * d + ord(c) - ord('0')
	#		c = INPUT_FILE.read(1)
	#	LAST = c
	#	YYLVAL = d
	#	return INTEGER.value
	elif 'A' <= c and c <= 'Z' or 'a' <= c and c <= 'z' or c == '_':
		s = c
		c = INPUT_FILE.read(1)
		while 'A' <= c and c <= 'Z' or 'a' <= c and c <= 'z' or c == '_' or '0' <= c and c <= '9':
			s += c
			c = INPUT_FILE.read(1)
		LAST = c
		YYLVAL = s
		return IDENTIFIER.value
	elif c == "'":
		s = ""
		c = INPUT_FILE.read(1)
		while c != "'" and c != '':
			if c == '\\':
				c = INPUT_FILE.read(1)
				s += {'n': '\n'}.get(c, c)
			else:
				s += c
			c = INPUT_FILE.read(1)
		YYLVAL = s
		return CHARACTER.value
	elif c == '%':
		s = c
		words = {'%%': MARK.value, '%{': None, '%token': TOKEN.value, '%empty': EMPTY.value, '%start': START.value, '%define': DEFINE.value}
		starts = [word[:i] for word in words for i in range(1, len(word))]
		#print(starts)
		while s in starts:
			c = INPUT_FILE.read(1)
			if c == '':
				break
			s += c
		if s not in words:
			LAST = s[-1]
			s = s[:-1]
		if s == '%{':
			s = ""
			c = ''
			while c != '}':
				while c != '%':
					s += c
					c = INPUT_FILE.read(1)
				c = INPUT_FILE.read(1)
				while c == '%':
					s += c
					c = INPUT_FILE.read(1)
			YYLVAL = s
			return CCODE.value
		else:
			if words[s] == MARK.value:
				MARKCOUNT += 1
			return words[s]
	elif c == '{':
		s = ""
		level = 0
		c = INPUT_FILE.read(1)
		while not (level == 0 and c == '}') and c != '':
			if c == '{':
				level += 1
			elif c == '}':
				level -= 1
			s += c
			c = INPUT_FILE.read(1)
		YYLVAL = s
		return ACTION.value
	else:
		return ord(c)

def yyerror(s):
	print("Error:", s, file = sys.stderr)

def yyparse(grammar):
	global TABLES, YYLVAL
	#type_stk = []
	value_stk = []
	state_stk = [0]

	look_ahead = yylex()

	while True:
#		print([grammar.tokens[t] for t in type_stk])
#		print([grammar.states[s] for s in state_stk])
		entry = grammar.actions[state_stk[-1]].get(look_ahead)
		if entry is None:
			entry = grammar.actions[state_stk[-1]].get(-1)
		action = entry[0]
		if action == 'SHIFT':
			#type_stk.append(look_ahead)
			value_stk.append(YYLVAL)
			state_stk.append(entry[1])
			look_ahead = yylex()
		elif action == 'APPLY':
			rule = grammar.rules[entry[1]]
			if len(rule.tokens) == 0:
				values = ()
			else:
				values = value_stk[-len(rule.tokens):]
				#type_stk[-len(rule.tokens):] = []
				value_stk[-len(rule.tokens):] = []
				state_stk[-len(rule.tokens):] = []
			if callable(rule.action):
				yyval = rule.action(*values)
			else:
				yyval = values
			current = rule.production.value
			entry = grammar.gotos[state_stk[-1]].get(current)
			if entry is None:
				entry = grammar.gotos[state_stk[-1]].get(-1)
			#type_stk.append(current)
			value_stk.append(yyval)
			state_stk.append(entry)
		elif action == 'ERROR':
			yyerror("parse error")
			return 1
		elif action == 'ACCEPT':
			return 0

#### Include templates

def convert_template(INPUT):
	OUTPUT = ""
	indent = ''
	for line in INPUT.split('\n'):
		if line.startswith('@@end'):
			indent = indent[:-1]
		elif line.startswith('@@else') or line.startswith('@@elif'):
			OUTPUT += indent[:-1] + line[2:] + '\n'
		elif line.startswith('@@') and not line.startswith('@@{'):
			OUTPUT += indent + line[2:] + '\n'
			if line.endswith(':'):
				indent += '\t'
		else:
			out = ''
			i = 0
			while i < len(line):
				if line[i:].startswith('@@{'):
					ix = line.find('}', i)
					out += '{' + line[i + 3:ix] + '}'
					i = ix + 1
				else:
					if line[i] == '{':
						out += "{{"
					elif line[i] == '}':
						out += "}}"
					elif line[i] == '"':
						out += "\\\""
					elif line[i] == '\\':
						out += "\\\\"
					else:
						out += line[i]
					i += 1
			OUTPUT += indent + "print(f\"" + out + "\", file = file)" + '\n'
	assert indent == ''
	return OUTPUT

def replace_placeholders(action, arg0, argN):
	while '$' in action:
		ix = action.find('$')
		if ix + 1 >= len(action):
			break
		digit = action[ix + 1]
		if digit == '$':
			action = action[:ix] + arg0 + action[ix + 2:]
		else:
			action = action[:ix] + argN.replace('@@', digit) + action[ix + 2:]
	return action

def import_definition(filename):
	with open(filename, 'r') as def_file:
		return convert_template(def_file.read())

def generate(grammar, filename, file = None):
	global MODULE_NAME

	tokens = grammar.tokens
	rules = grammar.rules
	states = grammar.states
	actions = grammar.actions
	gotos = grammar.gotos

	template = import_definition(filename)

	GLOBALS = {
		'file': file,
		'replace_placeholders': replace_placeholders,
		'tokens': grammar.tokens,
		'rules': grammar.rules,
		'states': grammar.states,
		'actions': grammar.actions,
		'gotos': grammar.gotos,
		'preamble': grammar.preamble,
		'postamble': grammar.postamble,
		'globals': grammar.globals,
		'module_name': MODULE_NAME,
	}
	exec(template, GLOBALS)

meta_grammar = GRAMMAR

TEMPLATE_NAME = sys.argv[1]

if len(sys.argv) > 2:
	INPUT_NAME = sys.argv[2]
	INPUT_FILE = open(INPUT_NAME, 'r')
	if len(sys.argv) > 3:
		OUTPUT_NAME = sys.argv[3]
		MODULE_NAME = os.path.split(os.path.splitext(OUTPUT_NAME)[0])[1]
	else:
		bare_name = os.path.splitext(INPUT_NAME)[0]
		MODULE_NAME = os.path.split(bare_name)[1]
		OUTPUT_NAME = MODULE_NAME + '.' + os.path.splitext(TEMPLATE_NAME)[0]
	OUTPUT_FILE = open(OUTPUT_NAME, 'w')
else:
	INPUT_NAME = 'stdin'
	INPUT_FILE = sys.stdin
	OUTPUT_NAME = 'out' + '.' + os.path.splitext(TEMPLATE_NAME)[0]
	MODULE_NAME = 'stdout'
	OUTPUT_FILE = sys.stdout

GRAMMAR = Grammar()
if yyparse(meta_grammar) != 0:
	exit(1)
compile_grammar(GRAMMAR, START_NAME)

generate(GRAMMAR, TEMPLATE_NAME, file = OUTPUT_FILE)

