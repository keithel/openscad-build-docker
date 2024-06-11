FROM openscad/openscad:dev
COPY src /sources/
COPY var-cache-apt-archives.tar* /
COPY install-packages.sh /root
RUN chmod u+x /root/install-packages.sh && /root/install-packages.sh
RUN useradd -m -s /bin/bash dev
COPY setup.sh /home/dev
WORKDIR /sources
RUN chown -R dev:dev /sources
RUN chown dev:dev /home/dev/setup.sh && chmod u+x /home/dev/setup.sh
USER dev
ENTRYPOINT [ "/bin/bash" ]
CMD [ "-c", "~/setup.sh" ]
