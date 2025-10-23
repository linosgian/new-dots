{
  unstable,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.services.deployedSvcs;
in
{
  services.postgresql = {
    package = unstablePkgs.postgresql_16;
    enable = true;
    ensureDatabases = [ "immich" ];
    dataDir = "/ssd-new/immich-db/pgdata";
    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
    extensions =
      ps: with ps; [
        pgvecto-rs
        vectorchord
        pgvector
      ];
    settings = {
      shared_preload_libraries = [
        "vectors.so"
        "vchord.so"
      ];
      search_path = "\"$user\", public, vectors";
    };
  };

  services.immich = {
    enable = true;
    port = cfg.defs.immich.port;
    host = "127.0.0.1";
    database.createDB = false;
    settings = {
      backup = {
        database = {
          cronExpression = "0 02 * * *";
          enabled = true;
          keepLastAmount = 14;
        };
      };

      ffmpeg = {
        accel = "qsv";
        accelDecode = true;
        acceptedAudioCodecs = [
          "aac"
          "mp3"
          "libopus"
          "pcm_s16le"
        ];
        acceptedContainers = [
          "mov"
          "ogg"
          "webm"
        ];
        acceptedVideoCodecs = [
          "h264"
        ];
        bframes = -1;
        cqMode = "auto";
        crf = 23;
        gopSize = 0;
        maxBitrate = "0";
        preferredHwDevice = "auto";
        preset = "ultrafast";
        refs = 0;
        targetAudioCodec = "aac";
        targetResolution = "720";
        targetVideoCodec = "h264";
        temporalAQ = false;
        threads = 0;
        tonemap = "hable";
        transcode = "required";
        twoPass = false;
      };

      image = {
        colorspace = "p3";
        extractEmbedded = false;
        fullsize = {
          enabled = false;
          format = "jpeg";
          quality = 80;
        };
        preview = {
          format = "jpeg";
          quality = 100;
          size = 2160;
        };
        thumbnail = {
          format = "webp";
          quality = 80;
          size = 250;
        };
      };

      job = {
        backgroundTask = {
          concurrency = 5;
        };
        faceDetection = {
          concurrency = 2;
        };
        library = {
          concurrency = 5;
        };
        metadataExtraction = {
          concurrency = 5;
        };
        migration = {
          concurrency = 5;
        };
        notifications = {
          concurrency = 5;
        };
        search = {
          concurrency = 5;
        };
        sidecar = {
          concurrency = 5;
        };
        smartSearch = {
          concurrency = 4;
        };
        thumbnailGeneration = {
          concurrency = 3;
        };
        videoConversion = {
          concurrency = 1;
        };
      };

      library = {
        scan = {
          cronExpression = "0 0 * * *";
          enabled = true;
        };
        watch = {
          enabled = true;
        };
      };

      logging = {
        enabled = true;
        level = "log";
      };

      machineLearning = {
        clip = {
          enabled = true;
          modelName = "immich-app/ViT-B-16-SigLIP__webli";
        };
        duplicateDetection = {
          enabled = true;
          maxDistance = 0.01;
        };
        enabled = true;
        facialRecognition = {
          enabled = true;
          maxDistance = 0.5;
          minFaces = 3;
          minScore = 0.7;
          modelName = "buffalo_l";
        };
        urls = [
          "http://localhost:3003"
        ];
      };

      map = {
        darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
        enabled = true;
        lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
      };

      metadata = {
        faces = {
          import = false;
        };
      };

      newVersionCheck = {
        enabled = true;
      };

      nightlyTasks = {
        clusterNewFaces = true;
        databaseCleanup = true;
        generateMemories = true;
        missingThumbnails = true;
        startTime = "00:00";
        syncQuotaUsage = true;
      };

      notifications = {
        smtp = {
          enabled = false;
          from = "";
          replyTo = "";
          transport = {
            host = "";
            ignoreCert = false;
            password = "";
            port = 587;
            username = "";
          };
        };
      };

      oauth = {
        autoLaunch = false;
        autoRegister = true;
        buttonText = "Login with OAuth";
        clientId = "";
        clientSecret = "";
        defaultStorageQuota = null;
        enabled = false;
        issuerUrl = "";
        mobileOverrideEnabled = false;
        mobileRedirectUri = "";
        profileSigningAlgorithm = "none";
        roleClaim = "immich_role";
        scope = "openid email profile";
        signingAlgorithm = "RS256";
        storageLabelClaim = "preferred_username";
        storageQuotaClaim = "immich_quota";
        timeout = 30000;
        tokenEndpointAuthMethod = "client_secret_post";
      };

      passwordLogin = {
        enabled = true;
      };

      reverseGeocoding = {
        enabled = true;
      };

      server = {
        externalDomain = "https://immich.lgian.com";
        loginPageMessage = "";
        publicUsers = true;
      };

      storageTemplate = {
        enabled = false;
        hashVerificationEnabled = true;
        template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
      };

      templates = {
        email = {
          albumInviteTemplate = "";
          albumUpdateTemplate = "";
          welcomeTemplate = "";
        };
      };

      theme = {
        customCss = "";
      };

      trash = {
        days = 30;
        enabled = true;
      };

      user = {
        deleteDelay = 7;
      };
    };
    accelerationDevices = [
      "/dev/dri/renderD128"
    ];
    mediaLocation = "/usr/src/app/upload";
  };

  # Maintain the old docker paths to avoid migrating
  systemd.services.immich-server.serviceConfig.BindPaths = [
    "/zfs/immich/uploads/:/usr/src/app/upload"
    "/ssd-new/immich-thumbs/thumbs:/usr/src/app/upload/thumbs"
    "/zfs/immich/config/:/config"
    "/zfs/nextcloud/root/data/lgian/files/linos/:/immich-storage/lgian"
    "/zfs/nextcloud/root/data/ilektra/files/p30/:/immich-storage/ilektra/p30"
    "/zfs/nextcloud/root/data/ilektra/files/camera_only/:/immich-storage/ilektra/camera_only"
    "/zfs/nextcloud/root/data/ilektra/files/videos/:/immich-storage/ilektra/videos"
    "/zfs/nextcloud/root/data/ilektra/files/iphones/Iphone8:/immich-storage/ilektra/iphones"
  ];
}
