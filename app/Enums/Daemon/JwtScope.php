<?php

namespace Luxodactyl\Enums\Daemon;

enum JwtScope: string
{
    case Websocket = 'websocket';
    case FileUpload = 'file-upload';
    case FileDownload = 'file-download';
    case BackupDownload = 'backup-download';
    case ServerTransfer = 'transfer';
}