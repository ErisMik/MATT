use chrono;
use clap::{arg, command};
use clokwerk::{Scheduler, TimeUnits};
use retry::{delay, retry};
use serde_derive::Deserialize;
use std::collections::HashMap;
use std::process::Command;
use std::thread;
use std::time::Duration;

const HEALTHCHECK_HOST: &str = "https://hc-ping.com";

#[derive(Clone, Debug, Deserialize)]
struct Repo {
    rsync: String,
    healthcheck_uuid: String,
    excludes: Option<Vec<String>>,
}

#[derive(Clone, Debug, Deserialize)]
struct Settings {
    destpath: String,
    rsync_opts: Vec<String>,
    repos: HashMap<String, Repo>,
}

impl Settings {
    fn new(config: config::Config) -> Result<Self, config::ConfigError> {
        config.try_deserialize()
    }
}

fn sync_repo(repo: Repo, name: String, destpath: String, opts: Vec<String>) {
    let base_url = format!("{}/{}", HEALTHCHECK_HOST, repo.healthcheck_uuid);
    reqwest::blocking::get(&format!("{}/start", base_url)).unwrap();

    let mut command = Command::new("rsync");
    for opt in opts.iter() {
        command.arg(opt.clone());
    }

    if let Some(excludes) = repo.excludes {
        for exclude in excludes {
            command.arg(format!("--exclude=\"{}\"", exclude));
        }
    }

    command.arg(repo.rsync);
    command.arg(format!("{}/{}", destpath, name));

    println!("Syncing {} with command {:?}", name, command);
    let result = retry(delay::Fixed::from_millis(5 * 60 * 1000).take(5), || {
        let mut child = command.spawn().expect("Command failed to start");
        let result = child.wait().unwrap();

        let return_code = result.code().unwrap();
        match return_code {
            0 => Ok(return_code),
            _ => Err(return_code),
        }
    });

    match result {
        Ok(return_code) => {
            reqwest::blocking::get(&format!("{}/{}", base_url, return_code)).unwrap()
        }
        Err(return_code) => {
            reqwest::blocking::get(&format!("{}/{}", base_url, return_code)).unwrap()
        }
    };
}

fn main() {
    let matches = command!()
        .arg(arg!(-c --config <FILE> "Sets a custom config file").default_value("matt.toml"))
        .get_matches();

    let config_filename = matches.get_one::<String>("config").unwrap();
    let config = config::Config::builder()
        .add_source(config::File::with_name(config_filename))
        .build()
        .unwrap();
    let settings = Settings::new(config).unwrap();

    let mut scheduler = Scheduler::with_tz(chrono::Utc);

    for (name, repo) in settings.repos.iter() {
        let name = name.clone();
        let repo = repo.clone();
        let destpath = settings.destpath.clone();
        let opts = settings.rsync_opts.clone();

        scheduler
            .every(1.day())
            .at("08:47:12")
            .run(move || sync_repo(repo.clone(), name.clone(), destpath.clone(), opts.clone()));
    }

    loop {
        scheduler.run_pending();
        thread::sleep(Duration::from_millis(500));
    }
}
