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
	npm install uglify-js --global
	node scripts/replace_with_env_vars.js
	elm make src/Main.elm --optimize --output public/client.js
	uglifyjs public/client.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | uglifyjs --mangle --output public/client.min.js
	elm make src/Booklet.elm --optimize --output public/booklet.js
	uglifyjs public/booklet.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | uglifyjs --mangle --output public/booklet.min.js
.PHONY: build-app

start-with-docker:
	docker run --rm -it \
		-p 8000:8000 \
		-v `pwd`:/pwd \
		-w /pwd \
		node:12 \
		make elm
