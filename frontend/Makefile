elm: node_modules
	npm install elm@latest-0.19.1
	which elm-live || npm install -g elm-live@^3.4.1
	node scripts/replace_with_env_vars.js
	elm-live src/Main.elm \
	--dir=public \
	--pushstate \
	--start-page=index.html \
	-- --output public/client.js
.PHONY: elm

node_modules: package.json
	npm install
.PHONY: node_modules

build-app: node_modules
	npm install elm@latest-0.19.1
	node scripts/replace_with_env_vars.js
	elm make src/Main.elm --output public/client.js
.PHONY: build-app
