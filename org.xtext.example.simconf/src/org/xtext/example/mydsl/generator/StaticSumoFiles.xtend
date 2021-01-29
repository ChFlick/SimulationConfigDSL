package org.xtext.example.mydsl.generator

import org.xtext.example.mydsl.domainmodel.Mode

class StaticSumoFiles {
	public static String START_SH = '''
		#!/bin/bash
		sumo -c ./generated.sumocfg
	'''

	public static String START_GUI_SH = '''
		#!/bin/bash
		sumo-gui -c ./generated.sumocfg
	'''

	public static String START_TRACI_SH = '''
		#!/bin/bash
		sumo -c ./generated.sumocfg --remote-port 8081
	'''

	public static String README = '''
		# SUMO Scenario
		- Execute `start-sumo.sh` to run the scenario in SUMO
		- Execute `start-sumo-gui.sh` to run the scenario in SUMO with GUI
		- Execute `start-sumo-traci.sh` to run the scenario in SUMO with a TraCI Server listening on Port `8081`
	'''

	def static getDockerfile(Mode mode) {
		return '''
			FROM ubuntu:bionic
			
			ENV SCRIPT_FOLDER /app
			ENV SUMO_VERSION 1.8.0
			ENV SUMO_HOME /usr/share/sumo
			
			RUN apt-get update && apt-get install -y \
			    cmake \
			    python3-pip \
			    g++ \
			    libxerces-c-dev libfox-1.6-dev libgdal-dev libproj-dev libgl2ps-dev \
			    swig \
			    wget
			RUN wget http://downloads.sourceforge.net/project/sumo/sumo/version%20$SUMO_VERSION/sumo-src-$SUMO_VERSION.tar.gz
			RUN tar xzf sumo-src-$SUMO_VERSION.tar.gz && \
			    mv sumo-$SUMO_VERSION $SUMO_HOME && \
			    rm sumo-src-$SUMO_VERSION.tar.gz
			
			RUN cd $SUMO_HOME  && \
			    mkdir build/cmake-build && cd build/cmake-build  && \
			    cmake ../..  && \
			    make -j$(nproc)
			
			ENV PATH "$PATH:/$SUMO_HOME/bin"
			
			WORKDIR $SCRIPT_FOLDER
								
			COPY . .
			
			CMD ["sumo","-c","generated.sumocfg"«IF mode == Mode.DOCKER_TRA_CI»,"--remote-port","8081"«ENDIF»]
		'''
	}

	def static getDockerReadme(Mode mode) {
		return '''
			# Dockerfile to run the SUMO Scenario
			
			## build						
			To build the docker image run:
			```
			docker build -t sumo:latest .
			```
			
			## run
			To execute the docker image after it is built run:						
			```
			docker run -i «IF mode == Mode.DOCKER_TRA_CI» -p 8081:8081 «ENDIF» sumo
			```
			
			«IF mode == Mode.DOCKER_TRA_CI»
				## TraCI
				When the container has started, you can connect your TraCI application at the container on port 8081.
			«ENDIF»								
		'''
	}
}
