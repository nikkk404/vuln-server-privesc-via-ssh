FROM ubuntu:22.04
WORKDIR /usr/src/app
COPY vuln.c .
COPY setup_internal.sh /tmp/setup_internal.sh
RUN chmod +x /tmp/setup_internal.sh && /tmp/setup_internal.sh
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
