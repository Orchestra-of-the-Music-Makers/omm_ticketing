elm: node_modules
	npm install elm@latest-0.19.1
	which elm-live || npm install -g elm-live@4.0.1
	node scripts/replace_with_env_vars.js
	elm-live src/Main.elm \
	--dir=public \
	--pushstate \
	--start-page=index.html \
	-- --output public/client.js
.PHONY: elm

booklet: node_modules
	npm install elm@latest-0.19.1
	which elm-live || npm install -g elm-live@4.0.1
	node scripts/replace_with_env_vars.js
	elm-live src/Booklet.elm \
	--dir=public \
	--pushstate \
	--start-page=booklet.html \
	-- --output public/booklet.js
.PHONY: booklet

node_modules: package.json
	npm install
.PHONY: node_modules

build-app: node_modules
	npm install elm@latest-0.19.1
	node scripts/replace_with_env_vars.js
	elm make src/Main.elm --output public/client.js
	elm make src/Booklet.elm --output public/booklet.js
.PHONY: build-app

start-with-docker:
	docker run --rm -it \
		-p 8000:8000 \
		-v `pwd`:/pwd \
		-w /pwd \
		node:12 \
		make elm
