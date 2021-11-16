declare USE_fish
if [ -n "${USE_fish}" ]
then
  echo "Setting up RUN for fish"
  mkdir -p /home/cloudcontrol/.config/fish
  echo "${RUN_COMMANDS}" >> /home/cloudcontrol/.config/fish/config.fish
else
  echo "Setting up RUN for bash"
  echo "${RUN_COMMANDS}" > /home/cloudcontrol/.run
  echo ". /home/cloudcontrol/.run" >> /home/cloudcontrol/.bashrc
fi
