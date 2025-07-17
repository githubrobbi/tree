#!/usr/bin/env rust-script
//! Version update script for Tree CLI project
//! Updates version in Cargo.toml and README.md
//! Usage: ./build/update_version.rs [patch|minor|major]

use std::fs;
use std::env;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    let increment_type = args.get(1).map(|s| s.as_str()).unwrap_or("patch");

    println!("🔄 Version update for Tree CLI project");
    println!("📋 Increment type: {}", increment_type);

    // Step 1: Get current version from Cargo.toml
    let current_version = get_current_version()?;
    println!("📍 Current version: {}", current_version);

    // Step 2: Calculate new version
    let new_version = increment_version(&current_version, increment_type)?;
    println!("🎯 New version: {}", new_version);

    // Step 3: Update files with new version
    update_cargo_toml(&current_version, &new_version)?;
    update_readme(&current_version, &new_version)?;
    
    println!("✅ All versions updated successfully!");
    println!("📦 Tree CLI is now at version: {}", new_version);
    
    Ok(())
}

fn get_current_version() -> Result<String, Box<dyn std::error::Error>> {
    let content = fs::read_to_string("Cargo.toml")?;
    
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("version") && trimmed.contains("=") {
            if let Some(start) = trimmed.find('"') {
                if let Some(end) = trimmed.rfind('"') {
                    if start < end {
                        return Ok(trimmed[start + 1..end].to_string());
                    }
                }
            }
        }
    }
    
    Err("Could not find version in Cargo.toml".into())
}

fn increment_version(current: &str, increment_type: &str) -> Result<String, Box<dyn std::error::Error>> {
    let version_parts: Vec<&str> = current.split('.').collect();
    if version_parts.len() != 3 {
        return Err(format!("Invalid version format: {}", current).into());
    }

    let major: u32 = version_parts[0].parse()?;
    let minor: u32 = version_parts[1].parse()?;
    let patch: u32 = version_parts[2].parse()?;

    let new_version = match increment_type {
        "major" => format!("{}.0.0", major + 1),
        "minor" => format!("{}.{}.0", major, minor + 1),
        "patch" | _ => format!("{}.{}.{}", major, minor, patch + 1),
    };

    Ok(new_version)
}

fn update_cargo_toml(current: &str, new: &str) -> Result<(), Box<dyn std::error::Error>> {
    println!("📝 Updating Cargo.toml...");
    
    let content = fs::read_to_string("Cargo.toml")?;
    let updated = content.replace(
        &format!("version = \"{}\"", current),
        &format!("version = \"{}\"", new)
    );
    
    fs::write("Cargo.toml", updated)?;
    println!("✅ Cargo.toml updated");
    Ok(())
}

fn update_readme(current: &str, new: &str) -> Result<(), Box<dyn std::error::Error>> {
    println!("📝 Updating README.md...");
    
    if let Ok(content) = fs::read_to_string("README.md") {
        let updated = content
            .replace(&format!("v{}", current), &format!("v{}", new))
            .replace(&format!("version {}", current), &format!("version {}", new));
        
        fs::write("README.md", updated)?;
        println!("✅ README.md updated");
    } else {
        println!("⚠️  README.md not found, skipping");
    }
    
    Ok(())
}
