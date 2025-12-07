# -*- coding: utf-8 -*-
import socket
import threading
import select
import signal
import sys
import time
import getopt
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-l", "--local", help="Local port to redirect traffic")
parser.add_argument("-p", "--port", help="Port to listen on")
parser.add_argument("-c", "--contr", help="Password for connection")
parser.add_argument("-r", "--response", help="HTTP response code")
parser.add_argument("-t", "--texto", help="Custom banner text")
parser.add_argument("-b", "--bind", help="Bind address")
parser.add_argument("-i", "--ip", help="Server IP")

args = parser.parse_args()

# ==================================
LISTENING_ADDR = '0.0.0.0'

if args.port:
    LISTENING_PORT = int(args.port)
else:
    print("[ERROR] You must enter the port to use as socks...")
    sys.exit(1)

if args.contr:
    PASS = str(args.contr)
else:
    PASS = str()

BUFLEN = 4096 * 4
TIMEOUT = 60

if args.local:
    DEFAULT_HOST = '127.0.0.1:' + args.local
else:
    print("[ERROR] You must select an existing port to redirect traffic...")
    sys.exit(1)

if args.response:
    STATUS_RESP = args.response
else:
    STATUS_RESP = '200'

if args.texto:
    STATUS_TXT = args.texto
else:
    STATUS_TXT = '<font color="#00FFFF">A</font><font color="#6bffff">D</font><font color="#99ffff">M</font><font color="#ebffff">@</font><font color="#ebffff">R</font><font color="#ccffff">u</font><font color="#99ffff">f</font><font color="#6bffff">u</font><font color="#2effff">9</font><font color="#00FFFF">9</font>'

RESPONSE = str('HTTP/1.1 ' + STATUS_RESP + ' <strong>' + STATUS_TXT + '</strong>\r\nContent-length: 0\r\n\r\nHTTP/1.1 200 Connection established\r\n\r\n').encode()


class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.daemon = True
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        try:
            self.soc.bind((self.host, self.port))
            self.soc.listen(0)
            self.running = True
            self.printLog("[+] Server started on {}:{}".format(self.host, self.port))

            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                except Exception as e:
                    if self.running:
                        self.printLog("[-] Accept error: {}".format(str(e)))
                    continue

                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        except Exception as e:
            self.printLog("[-] Server error: {}".format(str(e)))
        finally:
            self.running = False
            try:
                self.soc.close()
            except:
                pass

    def printLog(self, log):
        self.logLock.acquire()
        try:
            print(log)
            sys.stdout.flush()
        finally:
            self.logLock.release()

    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()

    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            if conn in self.threads:
                self.threads.remove(conn)
        finally:
            self.threadsLock.release()

    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()


class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.daemon = True
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = b''
        self.server = server
        self.log = 'Connection: ' + str(addr)

    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True

        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)

            # Decode buffer for string operations
            buffer_str = self.client_buffer.decode('utf-8', errors='ignore')

            hostPort = self.findHeader(buffer_str, 'X-Real-Host')

            if hostPort == '':
                hostPort = DEFAULT_HOST

            split = self.findHeader(buffer_str, 'X-Split')

            if split != '':
                try:
                    self.client.recv(BUFLEN)
                except:
                    pass

            if hostPort != '':
                passwd = self.findHeader(buffer_str, 'X-Pass')

                if len(PASS) != 0 and passwd == PASS:
                    self.method_CONNECT(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send(b'HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send(b'HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                self.log += ' - No X-Real-Host!'
                self.client.send(b'HTTP/1.1 400 NoXRealHost!\r\n\r\n')

        except Exception as e:
            self.log += ' - error: ' + str(e)
            self.server.printLog(self.log)
        finally:
            self.close()
            self.server.removeConn(self)

    def findHeader(self, head, header):
        aux = head.find(header + ': ')

        if aux == -1:
            return ''

        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')

        if aux == -1:
            return ''

        return head[:aux]

    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            if self.method == 'CONNECT':
                port = 443
            else:
                port = 80

        try:
            (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
            self.target = socket.socket(soc_family, soc_type, proto)
            self.targetClosed = False
            self.target.connect(address)
        except Exception as e:
            self.log += ' - Target connection error: ' + str(e)
            raise

    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path

        try:
            self.connect_target(path)
            self.client.sendall(RESPONSE)
            self.client_buffer = b''
            self.server.printLog(self.log)
            self.doCONNECT()
        except Exception as e:
            self.log += ' - Connect error: ' + str(e)
            self.server.printLog(self.log)

    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        
        while True:
            count += 1
            try:
                (recv, _, err) = select.select(socs, [], socs, 3)
            except Exception as e:
                self.server.printLog("[-] Select error: {}".format(str(e)))
                break

            if err:
                error = True

            if recv:
                for in_ in recv:
                    try:
                        data = in_.recv(BUFLEN)
                        if data:
                            if in_ is self.target:
                                self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]

                            count = 0
                        else:
                            error = True
                            break
                    except Exception as e:
                        self.server.printLog("[-] Transfer error: {}".format(str(e)))
                        error = True
                        break

            if count == TIMEOUT:
                error = True

            if error:
                break


def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    print("\n:-------PythonProxy-------:\n")
    print("Listening addr: " + LISTENING_ADDR)
    print("Listening port: " + str(LISTENING_PORT) + "\n")
    print(":-------------------------:\n")

    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()

    try:
        while True:
            time.sleep(2)
    except KeyboardInterrupt:
        print('\nStopping...')
        server.close()
        sys.exit(0)


if __name__ == '__main__':
    main()