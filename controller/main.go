// © Broadcom. All Rights Reserved.
// The term “Broadcom” refers to Broadcom Inc. and/or its subsidiaries.
// SPDX-License-Identifier: Apache-2.0

// Command controller runs the provider-agnostic VM API core reconciler.
package main

import (
	"flag"
	"os"

	"k8s.io/apimachinery/pkg/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	ctrl "sigs.k8s.io/controller-runtime"
	ctrlsig "sigs.k8s.io/controller-runtime/pkg/manager/signals"
	metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"

	vmv1alpha1 "github.com/vm-api/vm-api/api/v1alpha1"
	"github.com/vm-api/vm-api/controller/controllers/virtualmachine"
)

func main() {
	var metricsAddr string
	var probeAddr string
	flag.StringVar(&metricsAddr, "metrics-bind-address", "0", "The address the metrics endpoint binds to. \"0\" disables it.")
	flag.StringVar(&probeAddr, "health-probe-bind-address", ":8081", "The address the probe endpoint binds to.")
	flag.Parse()

	log := ctrl.Log.WithName("vm-api-controller")
	ctrl.SetLogger(log)

	scheme := runtime.NewScheme()
	if err := clientgoscheme.AddToScheme(scheme); err != nil {
		log.Error(err, "unable to add client-go scheme")
		os.Exit(1)
	}
	if err := vmv1alpha1.AddToScheme(scheme); err != nil {
		log.Error(err, "unable to add vm-api.io scheme")
		os.Exit(1)
	}

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme:                 scheme,
		HealthProbeBindAddress: probeAddr,
		Metrics: metricsserver.Options{
			BindAddress: metricsAddr,
		},
	})
	if err != nil {
		log.Error(err, "unable to start manager")
		os.Exit(1)
	}

	if err := virtualmachine.AddToManager(mgr); err != nil {
		log.Error(err, "unable to create controller", "controller", "VirtualMachine")
		os.Exit(1)
	}

	log.Info("starting manager")
	if err := mgr.Start(ctrlsig.SetupSignalHandler()); err != nil {
		log.Error(err, "problem running manager")
		os.Exit(1)
	}
}
