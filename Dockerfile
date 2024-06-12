FROM openscad/openscad:dev
COPY src /sources/
COPY var-cache-apt-archives.tar* /
COPY install-packages.sh /root
RUN chmod u+x /root/install-packages.sh && /root/install-packages.sh
RUN useradd -m -s /bin/bash dev
COPY build.sh /home/dev
COPY autorun.sh /home/dev
WORKDIR /sources
RUN chown -R dev:dev /sources
RUN chown dev:dev /home/dev/build.sh && chmod u+x /home/dev/build.sh
RUN chown dev:dev /home/dev/autorun.sh && chmod u+x /home/dev/autorun.sh
USER dev
ENTRYPOINT [ "/bin/bash" ]
CMD [ "-c", "~/autorun.sh" ]
