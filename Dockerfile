FROM ubuntu:25.04

RUN apt-get update \
	&& apt-get install --no-install-recommends -y \
	gcc=4:14.2.0-1ubuntu1 \
	g++=4:14.2.0-1ubuntu1 \
	git-svn=1:2.48.1-0ubuntu1 \
	ca-certificates=20241223 \
	neovim=0.9.5-10 \
	nodejs=20.18.1+dfsg-1ubuntu2 \
	curl=8.12.1-3ubuntu1 \
	btop=1.3.0-1 \
	npm=9.2.0~ds1-3 \
	unzip=6.0-28ubuntu6 \
	cmake=3.31.6-1ubuntu1 \
	make=4.4.1-1 \
	pkgconf=1.8.1-4 \
	bat=0.25.0-2 \
	fzf=0.60.3-1 \
	eza=0.20.24-1 \
	ncdu=1.21-2 \
	feh=3.10.3-1 \
	ripgrep=14.1.1-1 \
	fd-find=10.2.0-1 \
	fastfetch=2.38.0+dfsg-1ubuntu1 \
	apt-file=3.3 \
	wireguard-tools=1.0.20210914-1.1ubuntu2 \
	rsync=3.4.1+ds1-3 \
	tmux=3.5a-3 \
	opendoas=6.8.2-1 \
	cargo=1.84.0ubuntu1 \
	golang-go=2:1.24~2 \
	tree-sitter-cli=0.20.8-6 \
	starship=1.22.1-2

# More user friendly aliases
RUN ln -s "$(command -v fdfind)" /usr/bin/fd \
	&& ln -s "$(command -v doas)" /usr/bin/sudo

RUN git clone https://github.com/jstkdng/ueberzugpp.git -b v2.9.6 --depth 1 /usr/local/src/ueberzugpp \
	&& apt-get install --no-install-recommends -y \
	libtbb-dev=2022.0.0-2 \
	libxcb-image0-dev=0.4.0-2build1 \
	libxcb-res0-dev=1.17.0-2 \
	libvips-dev=8.16.0-2build1 \
	libsixel-dev=1.10.5-1 \
	libchafa-dev=1.14.5-1
RUN cmake -D CMAKE_BUILD_TYPE=Release -D ENABLE_OPENCV=OFF -S /usr/local/src/ueberzugpp/ -B /usr/local/src/ueberzugpp/build \
	&& cmake --build /usr/local/src/ueberzugpp/build -j "$(nproc)" \
	&& mv -v /usr/local/src/ueberzugpp/build/ueberzug /usr/local/bin/ueberzug \
	&& rm -r /usr/local/src/ueberzugpp

RUN git clone --depth=1 -b v0.51.1 https://github.com/jesseduffield/lazygit.git /usr/local/src/lazygit
WORKDIR /usr/local/src/lazygit
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazygit /usr/local/bin/lazygit \
	&& rm -r /usr/local/src/lazygit

RUN git clone --depth=1 -b v0.24.1 https://github.com/jesseduffield/lazydocker.git /usr/local/src/lazydocker
WORKDIR /usr/local/src/lazydocker
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazydocker /usr/local/bin/lazydocker \
	&& rm -r /usr/local/src/lazydocker

RUN git clone --depth=1 -b 0.63.0 https://github.com/Wilfred/difftastic.git /usr/local/src/difftastic
WORKDIR /usr/local/src/difftastic
RUN cargo build --release --locked \
	&& mv target/release/difft /usr/local/bin/difft \
	&& rm -r /usr/local/src/difftastic

RUN git clone --depth=1 -b v25.4.8 https://github.com/sxyazi/yazi.git /usr/local/src/yazi
WORKDIR /usr/local/src/yazi
RUN cargo build --release --locked \
	&& mv target/release/yazi /usr/local/bin/yazi \
	&& rm -r /usr/local/src/yazi

RUN apt-get remove -y golang-go cargo \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& rm -r /var/lib/apt/lists/* \
	&& rm -r /root/go \
	&& rm -r /root/.cargo \
	&& useradd -m saundersp

USER saundersp

WORKDIR /home/saundersp

# Copying local repository
# COPY --chown=saundersp:saundersp . dotfiles
# Cloning remote repository
RUN git clone --depth=1 https://github.com/saundersp/dotfiles.git

WORKDIR /home/saundersp/dotfiles

# Using neovim profile with LSP support
RUN cp nvim/init.lua nvim/server_init.lua \
	&& ./auto.sh s

ENTRYPOINT ["bash"]
