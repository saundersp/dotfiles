FROM ubuntu:25.10

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
	&& apt-get install --no-install-recommends -y \
	ca-certificates=20250419 \
	curl=8.14.1-2ubuntu1 \
	gpg=2.4.8-2ubuntu2.1 \
	&& echo 'deb http://download.opensuse.org/repositories/home:/justkidding/xUbuntu_25.04/ /' | tee /etc/apt/sources.list.d/home:justkidding.list \
	&& curl -fsSL https://download.opensuse.org/repositories/home:justkidding/xUbuntu_25.04/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_justkidding.gpg \
	&& apt-get update \
	&& apt-get install --no-install-recommends -y \
	gcc-15=15.2.0-4ubuntu4 \
	g++-15=15.2.0-4ubuntu4 \
	git-svn=1:2.51.0-1ubuntu1 \
	neovim=0.10.4-8build2 \
	nodejs=20.19.4+dfsg-1 \
	btop=1.3.2-0.1 \
	npm=9.2.0~ds1-3 \
	unzip=6.0-28ubuntu7 \
	cmake=3.31.6-2ubuntu6 \
	make-guile=4.4.1-2 \
	pkgconf=1.8.1-4build1 \
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
	ueberzugpp=2.9.8 \
	&& update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 50 \
	&& update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 50 \
	&& update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-15 50 \
	&& update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-15 50 \
	&& rustup default 1.92.0 \
	&& ln -s "$(command -v fdfind)" /usr/bin/fd \
	&& ln -s "$(command -v batcat)" /usr/bin/bat \
	&& go install github.com/jesseduffield/lazydocker@v0.24.3 \
	&& mv /root/go/bin/lazydocker /usr/bin/lazydocker \
	&& cargo install --locked difftastic@0.67.0 \
	&& mv /root/.cargo/bin/difft /usr/bin/difft \
	&& cargo install --force yazi-build@26.1.4 \
	&& cargo install --locked yazi-fm@26.1.4 \
	&& mv /root/.cargo/bin/yazi /usr/bin/yazi \
	&& apt-get remove -y golang-go rustup \
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
	&& ./auto.sh server \
	&& rm -r /home/saundersp/.npm /home/saundersp/.bash_logout /home/saundersp/.XDG/cache/yarn

ENTRYPOINT ["bash", "-l"]
