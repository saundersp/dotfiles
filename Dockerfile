FROM ubuntu:25.10

RUN apt-get update \
	&& apt-get install --no-install-recommends -y \
	gcc-15=15.2.0-2ubuntu1 \
	g++-15=15.2.0-2ubuntu1 \
	git-svn=1:2.51.0-1ubuntu1 \
	ca-certificates=20250419 \
	neovim=0.10.4-8build2 \
	nodejs=20.19.4+dfsg-1 \
	curl=8.14.1-1ubuntu3 \
	btop=1.3.2-0.1 \
	npm=9.2.0~ds1-3 \
	unzip=6.0-28ubuntu6 \
	cmake=3.31.6-2ubuntu4 \
	make-guile=4.4.1-2 \
	pkgconf=1.8.1-4 \
	bat=0.25.0-2 \
	fzf=0.60.3-1 \
	eza=0.21.0-1 \
	ncdu=1.22-1 \
	feh=3.10.3-1 \
	ripgrep=14.1.1-1 \
	fd-find=10.3.0-1 \
	fastfetch=2.49.0+dfsg-1 \
	apt-file=3.3 \
	rsync=3.4.1+ds1-5ubuntu1 \
	tmux=3.5a-3build1 \
	rustup=1.27.1-3 \
	golang-go=2:1.24~2 \
	tree-sitter-cli=0.22.6-6 \
	starship=1.22.1-6 \
	lazygit=0.53.0+ds1-1 \
	&& update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 50 \
	&& update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 50 \
	&& update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-15 50 \
	&& update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-15 50 \
	&& rustup default 1.89.0

# More user friendly aliases
RUN ln -s "$(command -v fdfind)" /usr/bin/fd

RUN git clone https://github.com/jstkdng/ueberzugpp.git -b v2.9.7 --depth 1 /usr/local/src/ueberzugpp \
	&& apt-get install --no-install-recommends -y \
	libtbb-dev=2022.1.0-1 \
	libxcb-image0-dev=0.4.0-2build1 \
	libxcb-res0-dev=1.17.0-2 \
	libvips-dev=8.16.1-1 \
	libsixel-dev=1.10.5-1 \
	libchafa-dev=1.14.5-1
RUN cmake -D CMAKE_BUILD_TYPE=Release -D ENABLE_OPENCV=OFF -S /usr/local/src/ueberzugpp/ -B /usr/local/src/ueberzugpp/build \
	&& cmake --build /usr/local/src/ueberzugpp/build -j "$(nproc)" \
	&& mv -v /usr/local/src/ueberzugpp/build/ueberzug /usr/local/bin/ueberzug \
	&& rm -r /usr/local/src/ueberzugpp

RUN git clone --depth=1 -b v0.24.1 https://github.com/jesseduffield/lazydocker.git /usr/local/src/lazydocker
WORKDIR /usr/local/src/lazydocker
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazydocker /usr/local/bin/lazydocker \
	&& rm -r /usr/local/src/lazydocker

RUN git clone --depth=1 -b 0.64.0 https://github.com/Wilfred/difftastic.git /usr/local/src/difftastic
WORKDIR /usr/local/src/difftastic
RUN cargo build --release --locked \
	&& mv target/release/difft /usr/local/bin/difft \
	&& rm -r /usr/local/src/difftastic

RUN git clone --depth=1 -b v25.5.31 https://github.com/sxyazi/yazi.git /usr/local/src/yazi
WORKDIR /usr/local/src/yazi
RUN cargo build --release --locked \
	&& mv target/release/yazi /usr/local/bin/yazi \
	&& rm -r /usr/local/src/yazi

RUN apt-get remove -y golang-go rustup \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& rm -r /var/lib/apt/lists/* /root/go /root/.cargo /root/.rustup /root/.cache /root/.config \
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
	&& ./auto.sh s \
	&& rm -r /home/saundersp/.npm /home/saundersp/.bash_logout /home/saundersp/.XDG/cache/yarn

ENTRYPOINT ["bash"]
