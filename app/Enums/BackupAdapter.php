<?php

namespace Pterodactyl\Enums;

enum BackupAdapter: string
{
    case Wings = 'wings';
    case S3 = 's3';
    case Elytra = 'elytra';
    case RusticLocal = 'rustic_local';
    case RusticS3 = 'rustic_s3';

    public function isRustic(): bool
    {
        return in_array($this, [self::RusticLocal, self::RusticS3], true);
    }

    public function isLocal(): bool
    {
        return in_array($this, [self::Wings, self::Elytra, self::RusticLocal], true);
    }

    public function requiresS3Bucket(): bool
    {
        return in_array($this, [self::S3, self::RusticS3], true);
    }

    public function getRepositoryType(): ?string
    {
        return match ($this) {
            self::RusticLocal => 'local',
            self::RusticS3 => 's3',
            default => null,
        };
    }

    public function getElytraAdapterType(): string
    {
        return match ($this) {
            self::Elytra => 'elytra',
            self::S3 => 's3',
            self::RusticLocal => 'rustic_local',
            self::RusticS3 => 'rustic_s3',
            default => $this->value,
        };
    }

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
