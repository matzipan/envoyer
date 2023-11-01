use docker_command::*;

extern crate melib;

use log::info;
use melib::smol;
use melib::smtp::*;

use std::thread;
use std::time::Duration;

const TEST_SERVER_CONTAINER_NAME: &str = "envoyer_test_server";

fn get_server_conf() -> SmtpServerConf {
    SmtpServerConf {
        hostname: "localhost".into(),
        port: 3025,
        security: SmtpSecurity::None,
        extensions: SmtpExtensionSupport::default(),
        auth: SmtpAuth::None,
        envelope_from: "test_server_sender@envoyer.test".into(),
    }
}

async fn setup_server() {
    let server_config = get_server_conf();

    info!("Waiting for the server to be ready");
    smol::Timer::after(Duration::from_secs(5)).await;

    info!("Connecting");
    let mut connection = SmtpConnection::new_connection(server_config)
        .await
        .expect("Server connection not created");

    loop {
        info!("Sending an email");
        connection
            .mail_transaction(
                r#"To: app_receiver@envoyer.test
Subject: Fwd: SMTP TEST
From: Me <test_server_sender@envoyer.test>
Message-Id: <E1hSjnr-0003fN-RL@pppppp>
Date: Mon, 13 Jul 2020 09:02:15 +0300

Message content here"#,
                Some(&[melib::Address::new(None, "app_receiver@envoyer.test".into())]),
            )
            .await
            .expect("Message not sent");

        smol::Timer::after(Duration::from_secs(5)).await;
    }
}

fn main() {
    let _thread_handle = thread::spawn(|| {
        smol::block_on(setup_server());
    });

    let launcher = Launcher::auto().expect("Docker launcher not found");

    info!("Stopping any previous containers");
    let _ = launcher
        .stop(StopOpt {
            containers: vec![TEST_SERVER_CONTAINER_NAME.into()],
            time: Some(1),
        })
        .run();

    info!("Starting greenmail server container");
    launcher
        .run(RunOpt {
            image: "docker.io/greenmail/standalone:2.0.0".into(),
            name: Some(TEST_SERVER_CONTAINER_NAME.into()),
            publish: vec![
                PublishPorts {
                    container: 3025.into(),
                    host: Some(3025.into()),
                    ..Default::default()
                },
                PublishPorts {
                    container: 3110.into(),
                    host: Some(3110.into()),

                    ..Default::default()
                },
                PublishPorts {
                    container: 3143.into(),
                    host: Some(3143.into()),
                    ..Default::default()
                },
                PublishPorts {
                    container: 3465.into(),
                    host: Some(3465.into()),
                    ..Default::default()
                },
                PublishPorts {
                    container: 3993.into(),
                    host: Some(3993.into()),
                    ..Default::default()
                },
                PublishPorts {
                    container: 3995.into(),
                    host: Some(3995.into()),
                    ..Default::default()
                },
            ],
            remove: true,
            env: vec![(
                "GREENMAIL_OPTS".into(),
                "-Dgreenmail.setup.test.all -Dgreenmail.hostname=0.0.0.0 -Dgreenmail.auth.disabled -Dgreenmail.verbose".into(),
            )],
            ..Default::default()
        })
        .run()
        .expect("Unable to start greenmail");
}
