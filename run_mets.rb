#!/usr/bin/env ruby

$: << "."
require 'config/environment'
require 'time'
require 'pp'
I18n.locale = "sv" # Force swedish...
job_to_process = Job.find_job_waiting_for_mets

# Check if we have anything to do...
exit if !job_to_process

STDERR.puts("#{Time.now} (#{job_to_process.id}): Starting control...")
if !job_to_process.mets_control
  # Control failed, write error and exit.
  STDERR.puts("#{Time.now} (#{job_to_process.id}): Control failed, check quarantine...")
  exit
end

# If mets_control went well it's OK to get the page_count
job_to_process.page_count = job_to_process.mets_page_count

STDERR.puts("#{Time.now} (#{job_to_process.id}): Starting production...")
if !job_to_process.mets_produce
  # Production failed, write error and exit.
  STDERR.puts("#{Time.now} (#{job_to_process.id}): Production failed, check quarantine...")
  exit
end

STDERR.puts("#{Time.now} (#{job_to_process.id}): Done.")
