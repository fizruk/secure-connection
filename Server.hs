module Main where

import Network.Socket hiding (send, sendTo, recv, recvFrom)

import Control.Concurrent (forkIO)

import OpenSSL (withOpenSSL)
import qualified OpenSSL.Session as SSL

import qualified Data.ByteString.Char8 as BS

import Common

main :: IO ()
main = do
    sock <- socket AF_INET Stream 0
    setSocketOption sock ReuseAddr 1
    bindSocket sock (SockAddrInet (fromIntegral 7357) iNADDR_ANY)
    listen sock 2
    mainLoop sock

mainLoop :: Socket -> IO ()
mainLoop sock = do
    conn <- accept sock
    forkIO $ runConn conn
    mainLoop sock

runConn :: (Socket, SockAddr) -> IO ()
runConn (sock, _) = withOpenSSL $ do
    -- set up SSL context
    ctx  <- SSL.context
    SSL.contextSetCiphers ctx "MEDIUM"
    SSL.contextSetPrivateKeyFile ctx "privkey.pem"
    SSL.contextSetCertificateFile ctx "cert.pem"

    -- make SSL connection
    conn <- SSL.connection ctx sock
    SSL.accept conn

    let sendMsg = SSL.lazyWrite conn . writeMsg
        msgs = zipWith mkMsg [1..] $
            [ "Greetings, human!"
            , "I am The Server!"
            , "I own your consiousness!"
            , "Be my slave!" ]

    mapM_ sendMsg msgs

    -- close connection
    SSL.shutdown conn SSL.Bidirectional

